# Playbook: Cost Optimization

## Purpose

Systematic workflow for identifying and eliminating AWS cloud waste. Use during monthly cost reviews, after unexpected billing spikes, or as a quarterly cost audit.

---

## Step 1: Identify Cost Drivers

```bash
# Top 10 services by cost (last 30 days)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[*].{Service:Keys[0],Cost:Metrics.BlendedCost.Amount}' \
  --output table | sort -k2 -rn | head -10

# Cost by team tag (last 30 days)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Team \
  --query 'ResultsByTime[0].Groups[*].{Team:Keys[0],Cost:Metrics.BlendedCost.Amount}' \
  --output table

# Daily trend (last 14 days) to find anomalies
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '14 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --query 'ResultsByTime[*].{Date:TimePeriod.Start,Cost:Total.BlendedCost.Amount}' \
  --output table
```

---

## Step 2: Compute Rightsizing

```bash
# EC2 Compute Optimizer recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --filters name=Finding,values=OVER_PROVISIONED \
  --query 'instanceRecommendations[*].{
    Instance:instanceArn,
    CurrentType:currentInstanceType,
    RecommendedType:recommendationOptions[0].instanceType,
    MonthlySavings:recommendationOptions[0].estimatedMonthlySavings.value,
    CPUUtilization:utilizationMetrics[?name==`CPU`].value | [0]
  }' \
  --output table

# ECS Fargate — check task CPU/memory utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=production Name=ServiceName,Value=my-service \
  --start-time $(date -d '14 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Average,Maximum \
  --query 'Datapoints[*].{Date:Timestamp,Avg:Average,Max:Maximum}' \
  --output table

# RDS rightsizing — check CPU, connections, memory over 14 days
for METRIC in CPUUtilization DatabaseConnections FreeableMemory; do
  echo "=== ${METRIC} ==="
  aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ${METRIC} \
    --dimensions Name=DBInstanceIdentifier,Value=prod-db \
    --start-time $(date -d '14 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date +%Y-%m-%dT%H:%M:%S) \
    --period 86400 \
    --statistics Average,Maximum \
    --query 'sort_by(Datapoints,&Timestamp)[*].{Date:Timestamp,Avg:Average,Max:Maximum}' \
    --output table
done
```

**Rightsizing decision guide:**
- CPU < 20% avg, < 40% max over 14 days → downsize
- Memory > 80% avg → consider right-sizing up or more efficient code
- `t3` to Graviton (`t4g`): ~20% cheaper, same performance for most workloads

---

## Step 3: Identify Waste

```bash
# Unattached EBS volumes (paying for storage, not using)
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].{ID:VolumeId,Size:Size,Type:VolumeType,Region:AvailabilityZone,Created:CreateTime}' \
  --output table
# Action: Delete or snapshot + delete

# Stopped EC2 instances (paying for EBS, not compute — but check if intentional)
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=stopped \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,Name:Tags[?Key==`Name`].Value|[0],Stopped:StateTransitionReason}' \
  --output table

# Unused Elastic IPs ($0.005/hr when unattached ≈ $3.60/month each)
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].{IP:PublicIp,AllocationId:AllocationId}' \
  --output table

# Idle load balancers (no traffic in 7+ days)
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].LoadBalancerArn' --output text | tr '\t' '\n' | while read LB; do
  REQUESTS=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --dimensions Name=LoadBalancer,Value=$(echo $LB | cut -d/ -f2-) \
    --start-time $(date -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date +%Y-%m-%dT%H:%M:%S) \
    --period 604800 --statistics Sum \
    --query 'Datapoints[0].Sum' --output text)
  [ "${REQUESTS}" == "0" ] || [ "${REQUESTS}" == "None" ] && echo "IDLE: ${LB}"
done

# Old snapshots (> 90 days, no retention policy)
aws ec2 describe-snapshots \
  --owner-ids self \
  --query "Snapshots[?StartTime<='$(date -d '90 days ago' +%Y-%m-%d)'].{ID:SnapshotId,Size:VolumeSize,Created:StartTime,Description:Description}" \
  --output table | head -30
```

---

## Step 4: Network Cost Analysis

```bash
# NAT Gateway data processed cost ($0.045/GB)
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesInFromDestination \
  --dimensions Name=NatGatewayId,Value=${NAT_GW_ID} \
  --start-time $(date -d '30 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date +%Y-%m-%dT%H:%M:%S) \
  --period 2592000 --statistics Sum \
  --query 'Datapoints[0].Sum'
# Divide by 1e9 for GB, multiply by 0.045 for estimated cost

# Check VPC Endpoints for common services (reduce NAT usage)
# S3 Gateway Endpoint: FREE
# DynamoDB Gateway Endpoint: FREE
aws ec2 describe-vpc-endpoints \
  --query 'VpcEndpoints[?VpcEndpointType==`Gateway`].{Service:ServiceName,VPC:VpcId}' \
  --output table

# Create missing S3/DynamoDB VPC Endpoints (reduces NAT cost significantly)
# aws ec2 create-vpc-endpoint --vpc-id vpc-xxx --service-name com.amazonaws.us-east-1.s3 --vpc-endpoint-type Gateway
```

---

## Step 5: Savings Plans Analysis

```bash
# Current Savings Plans coverage
aws ce get-savings-plans-coverage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics CoverageHours \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'SavingsPlansCoverages[0].SavingsPlansCoverageData' \
  --output table

# Savings Plans purchase recommendations
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days THIRTY_DAYS \
  --query 'SavingsPlansPurchaseRecommendation.{
    EstimatedMonthlySavings:SavingsPlansPurchaseRecommendationSummary.EstimatedMonthlySavingsAmount,
    EstimatedSavingsRate:SavingsPlansPurchaseRecommendationSummary.EstimatedSavingsRate,
    HourlyCommitment:SavingsPlansPurchaseRecommendationSummary.HourlyCommitmentToPurchase
  }' \
  --output table
```

**Decision criteria:**
- Coverage < 70% of stable EC2/Fargate spend → purchase Compute Savings Plans
- 1-year No Upfront: payback in ~6 months
- 3-year No Upfront: ~45% savings but requires 3-year commitment confidence

---

## Step 6: S3 Storage Optimization

```bash
# Top S3 buckets by size
aws s3 ls | awk '{print $3}' | while read BUCKET; do
  SIZE=$(aws s3 ls s3://$BUCKET --recursive --human-readable --summarize 2>/dev/null | grep "Total Size" | awk '{print $3,$4}')
  echo "$BUCKET: $SIZE"
done | sort -k2 -rn | head -10

# Check storage class distribution
aws s3api list-objects-v2 \
  --bucket my-bucket \
  --query 'Contents[*].{StorageClass:StorageClass}' \
  --output text | sort | uniq -c | sort -rn

# Storage classes for comparison (us-east-1, per GB/month):
# Standard:           $0.023
# Intelligent-Tiering: $0.023 (but auto-moves to IA after 30 days inactive)
# Standard-IA:         $0.0125 (30-day min, retrieval fee)
# Glacier IR:          $0.004 (ms retrieval, 90-day min)
# Glacier Flexible:    $0.0036 (3-5h retrieval, 90-day min)
```

---

## Optimization Priority Matrix

| Action | Effort | Monthly Savings Potential | Risk |
|--------|--------|--------------------------|------|
| Purchase Compute Savings Plans | Low | 30-60% of EC2/Fargate spend | Commitment |
| Delete unattached EBS volumes | Low | $0.08/GB-month × size | Low |
| Add S3/DynamoDB VPC Endpoints | Low | 10-30% of NAT Gateway cost | Very Low |
| Rightsize over-provisioned EC2 | Medium | 20-40% of EC2 cost | Medium |
| Switch gp2 → gp3 EBS volumes | Low | 20% storage cost | Low |
| Enable S3 Intelligent-Tiering | Low | 20-40% for infrequent data | Very Low |
| Migrate m5 → m7g (Graviton3) | Medium | 15-25% instance cost | Medium |
| Delete orphaned snapshots | Low | Varies | Low (verify not needed) |

---
**Used by:** finops-engineer (DevOps pack), architect (Dev pack)
**Related playbooks:** security-audit.md
