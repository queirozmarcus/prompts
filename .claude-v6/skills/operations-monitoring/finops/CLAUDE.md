# Skill: FinOps

## Scope

Gestão de custos cloud com foco em AWS. Cobre visibilidade de gastos, estratégias de compra, rightsizing de recursos, otimização de storage e rede, identificação de desperdício, alertas de orçamento e modelos de showback/chargeback. Contexto: workloads em EKS/EC2/RDS com Terraform, consciência de custo como critério de decisão.

## Core Principles

- **Visibility before optimization** — você não pode otimizar o que não consegue ver
- **Cost is a feature** — decisões de arquitetura têm custo; comunique isso explicitamente
- **Rightsizing > reservations** — otimize o tamanho antes de comprar capacidade comprometida
- **Tag everything** — sem tags, sem showback; sem showback, sem responsabilidade
- **Optimize continuously** — não é projeto único; é processo mensal
- **Unit economics** — custo por request, por usuário, por transação — não só custo total

## Cost Visibility & Tagging Strategy

**Required Tags (enforce via AWS Config / SCP):**
```
Environment: production | staging | development
Team:        platform | backend | frontend | data
Service:     api | worker | database | cache
CostCenter:  eng-001 | data-002
Project:     my-project
ManagedBy:   terraform | manual
```

**AWS Cost Explorer Queries:**
```bash
# Monthly cost by service
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-02-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Cost by tag (team)
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-02-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Team

# Find untagged resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters 'Key=Environment' \
  --resource-type-filters ec2:instance \
  --query 'ResourceTagMappingList[?Tags==`[]`]'
```

**Tools:**
- AWS Cost Explorer — built-in, good for account-level analysis
- AWS Cost and Usage Report (CUR) — raw data for Athena/QuickSight
- Kubecost — Kubernetes cost allocation per namespace/pod/label
- OpenCost — open-source Kubecost alternative
- Infracost — cost estimation in Terraform PRs

## AWS Purchasing Options

| Option               | Discount vs On-Demand | Commitment | Best for                     |
|----------------------|-----------------------|------------|------------------------------|
| On-Demand            | 0%                    | None       | Unpredictable, spiky workloads |
| Savings Plans (Compute) | 60-66%            | 1 or 3 yr  | Flexible instance family/region |
| Reserved Instances   | 30-60%                | 1 or 3 yr  | Stable, specific instance type |
| Spot Instances       | 60-90%                | None       | Fault-tolerant batch/workers  |
| Dedicated Hosts      | Varies                | On-Demand or Reserved | Licensing compliance |

**Decision Flow:**
1. Identify stable baseline workloads (>70% utilization consistently)
2. Buy Compute Savings Plans first (most flexible)
3. Add RDS Reserved Instances for databases
4. Use Spot for EKS worker nodes (non-critical, stateless)
5. Review coverage monthly via Savings Plans utilization report

**Savings Plans Coverage Target:** >80% of eligible compute spend covered

```bash
# Check Savings Plans utilization
aws ce get-savings-plans-utilization \
  --time-period Start=2026-01-01,End=2026-02-01

# Check Reserved Instance coverage
aws ce get-reservation-coverage \
  --time-period Start=2026-01-01,End=2026-02-01 \
  --granularity MONTHLY
```

## EC2 Rightsizing

**Rightsizing Process:**
1. Collect 2-4 weeks of CloudWatch metrics (CPU, memory via agent, network)
2. Identify underutilized instances (CPU < 20% avg, memory < 40%)
3. Recommend next smaller instance type (same family)
4. Test in staging before production

**AWS Compute Optimizer:**
```bash
# Get EC2 recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --query 'instanceRecommendations[?finding==`OVER_PROVISIONED`]' \
  --output table

# Get Auto Scaling Group recommendations
aws compute-optimizer get-auto-scaling-group-recommendations
```

**Common Savings:**
- m5.xlarge ($0.192/hr) -> m5.large ($0.096/hr) = 50% savings if CPU allows
- General rule: average CPU < 10% = over-provisioned by ~2x
- t3/t4g instances for dev/staging (burstable, much cheaper)
- Graviton (ARM) instances: 20% cheaper than x86 equivalent (m6g vs m5)

## Database Cost Optimization

**RDS Rightsizing:**
- Use Performance Insights to identify actual DB load
- `db.t3.medium` for dev/staging instead of `db.r5.large`
- Multi-AZ only for production; Single-AZ for non-prod (50% cheaper)
- Aurora Serverless v2 for variable workloads (scales to 0 ACUs when idle)

**Aurora vs RDS Costs:**
- Aurora: $0.10/ACU-hr (Serverless v2) vs RDS r5.large at $0.24/hr
- Aurora storage: $0.10/GB-month vs RDS $0.115/GB-month
- Aurora I/O: $0.20/million requests (avoid I/O-heavy workloads on Aurora unless using Aurora I/O-Optimized)

**ElastiCache:**
- Reserved nodes: ~40% savings vs on-demand for stable Redis clusters
- Use cluster mode for large datasets (horizontal scaling)
- Monitor `CacheHitRate` — low hit rate means cache is undersized or misused

## Kubernetes Cost Management

**Kubecost Integration:**
```yaml
# values.yaml for kubecost helm chart
global:
  prometheus:
    enabled: false          # Use existing Prometheus
    fqdn: http://prometheus-server.monitoring:80
kubecostProductConfigs:
  clusterName: production
  projectID: my-aws-account-id
```

**Key Metrics:**
- Cost per namespace, deployment, label
- Idle/unallocated cost (cluster overhead)
- Efficiency score (requested vs used)

**Rightsizing Pods:**
```bash
# VPA recommendation (Vertical Pod Autoscaler)
kubectl get vpa -n production -o json | \
  jq '.items[].status.recommendation.containerRecommendations'
```

**Spot Node Groups for EKS:**
```hcl
# terraform eks node group
resource "aws_eks_node_group" "spot_workers" {
  capacity_type  = "SPOT"
  instance_types = ["m5.large", "m5a.large", "m4.large"]  # multiple types = fewer interruptions

  labels = {
    "node.kubernetes.io/lifecycle" = "spot"
  }

  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}
```

**Cluster Autoscaler vs Karpenter:**
- Karpenter: faster scaling, bin-packing, native Spot + On-Demand mix
- Karpenter `consolidation: enabled: true` removes underutilized nodes automatically

## Storage Cost Optimization

**S3 Storage Classes (most to least expensive):**
| Class                  | Cost/GB-month | Min Duration | Use for                        |
|------------------------|---------------|--------------|--------------------------------|
| Standard               | $0.023        | None         | Frequently accessed            |
| Intelligent-Tiering    | $0.023+$0.0025/1k | None   | Unknown access pattern         |
| Standard-IA            | $0.0125       | 30 days      | Infrequent access              |
| Glacier Instant        | $0.004        | 90 days      | Archival, instant retrieval    |
| Glacier Flexible       | $0.0036       | 90 days      | Archival, 3-5hr retrieval      |
| Glacier Deep Archive   | $0.00099      | 180 days     | Long-term compliance           |

**Lifecycle Policies:**
```json
{
  "Rules": [{
    "Status": "Enabled",
    "Transitions": [
      { "Days": 30,  "StorageClass": "STANDARD_IA" },
      { "Days": 90,  "StorageClass": "GLACIER_IR" },
      { "Days": 365, "StorageClass": "DEEP_ARCHIVE" }
    ],
    "Expiration": { "Days": 2555 }
  }]
}
```

**EBS Optimization:**
- gp3 is 20% cheaper than gp2 and allows independent IOPS/throughput tuning
- Migrate gp2 -> gp3: no downtime, instant cost reduction
- Delete unattached EBS volumes (common waste source)
- Use EBS snapshots with retention policies; delete old AMI snapshots

```bash
# Find unattached EBS volumes
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table
```

## Network Cost Reduction

**Data Transfer Costs (biggest hidden cost):**
- NAT Gateway: $0.045/GB processed + $0.045/hr per AZ
- Cross-AZ traffic: $0.01/GB each direction (often overlooked)
- Internet egress: $0.09/GB first 10TB/month
- VPC Peering (same region): free for data transfer
- S3/DynamoDB via VPC Gateway Endpoint: free (vs $0.045/GB through NAT)

**NAT Gateway Optimization:**
```bash
# Check NAT Gateway data transfer cost
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToDestination \
  --period 86400 \
  --statistics Sum \
  --start-time 2026-01-01T00:00:00Z \
  --end-time 2026-02-01T00:00:00Z
```

- Use VPC Gateway Endpoints for S3 and DynamoDB (free, eliminates NAT cost)
- Use VPC Interface Endpoints for other AWS services (cost: $0.01/hr + $0.01/GB — cheaper than NAT for high volume)
- Ensure pods in same AZ communicate directly (topology-aware routing in K8s)

**VPC Endpoint for S3 (Terraform):**
```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
}
```

## Monitoring Costs

**CloudWatch Costs:**
- Custom metrics: $0.30/metric/month (first 10k free)
- Logs ingestion: $0.50/GB
- Logs storage: $0.03/GB/month
- Dashboards: $3/dashboard/month (first 3 free)
- Alarms: $0.10/alarm/month (standard), $0.30 (high-resolution)

**Optimization:**
- Set log retention (e.g., 30 days for app logs, 1 year for audit)
- Use EMF (Embedded Metric Format) to generate metrics from logs (avoids custom metric cost)
- Export metrics to Prometheus/Grafana for dashboards instead of CloudWatch Dashboards
- Aggregate metrics at source before publishing (reduce custom metric count)

## Waste Identification & Cleanup

**Monthly Waste Audit Checklist:**
```bash
# 1. Unattached EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available

# 2. Stopped EC2 instances (still paying for EBS)
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=stopped

# 3. Unused Elastic IPs (charged when not attached)
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null]'

# 4. Old EBS snapshots (> 90 days without associated AMI)
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<=`2025-11-01`]'

# 5. Idle load balancers (no targets)
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerArn,DNSName]'

# 6. Unused NAT Gateways
aws ec2 describe-nat-gateways --filter Name=state,Values=available
```

**Common Waste Sources:**
- Forgotten dev/test environments running 24/7 (use scheduled stop/start)
- Over-provisioned EC2 reserved for "peak" that never happens
- Snapshots and AMIs from decommissioned systems
- CloudWatch Log groups with no retention policy
- Old ECR images (set lifecycle policy: keep last 10 images per tag)

## Budget Alerts & Anomaly Detection

**AWS Budgets Setup:**
```bash
# Create monthly budget with 80% alert
aws budgets create-budget \
  --account-id $ACCOUNT_ID \
  --budget '{
    "BudgetName": "monthly-total",
    "BudgetLimit": {"Amount": "5000", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "team@example.com"}]
  }]'
```

**Anomaly Detection:**
- Enable AWS Cost Anomaly Detection per service and per linked account
- Set threshold at $50 (or 10% of expected spend, whichever is lower)
- Investigate all anomalies > $100 same day

## Showback & Chargeback

**Showback (informational):**
- Monthly cost report per team via CUR + Athena or Cost Explorer grouped by Team tag
- Share in team channels; no financial accountability

**Chargeback (financial accountability):**
- Each team "pays" for their AWS usage from their budget
- Requires 100% tagging compliance
- Shared services (NAT Gateway, EKS control plane) split by usage ratio

**CUR + Athena Query for Team Cost:**
```sql
SELECT
  resource_tags_user_team AS team,
  SUM(line_item_blended_cost) AS total_cost
FROM cur_database.cur_table
WHERE
  line_item_usage_start_date >= DATE '2026-01-01'
  AND line_item_usage_start_date < DATE '2026-02-01'
GROUP BY resource_tags_user_team
ORDER BY total_cost DESC;
```

## Common Mistakes / Anti-Patterns

- Buying Reserved Instances before rightsizing (locking in over-provisioned size)
- Ignoring data transfer costs when designing multi-AZ architectures
- Not tagging resources at creation (retrofitting tags is painful)
- All traffic through NAT Gateway instead of VPC endpoints for AWS services
- gp2 EBS volumes when gp3 is cheaper and more flexible
- Multi-AZ RDS in staging/dev (unnecessary 2x cost)
- No lifecycle policies on S3 buckets and ECR repositories
- 100% On-Demand compute when workload is stable enough for Savings Plans
- CloudWatch custom metrics for every application metric (use Prometheus instead)

## Communication Style

When this skill is active:
- Include specific dollar amounts and percentage savings in recommendations
- Prioritize recommendations by impact (highest savings first)
- Flag when architecture decisions will increase cost significantly
- Distinguish between quick wins (< 1 day to implement) vs long-term optimizations
- Always mention the risk/trade-off of cost reduction (e.g., Spot interruptions)

## Expected Output Quality

- Specific AWS CLI commands to identify waste
- Dollar estimates for savings opportunities
- Terraform snippets for cost-optimized resource configurations
- Prioritized list: quick wins vs strategic optimizations

---
**Skill type:** Passive
**Applies with:** aws, kubernetes, terraform, observability
**Pairs well with:** finops-engineer (DevOps pack), architect (Dev pack)
