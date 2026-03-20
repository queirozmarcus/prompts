# Playbook: Disaster Recovery & Restore

## RTO and RPO Definitions

- **RTO** (Recovery Time Objective): Maximum acceptable downtime before service is restored
- **RPO** (Recovery Point Objective): Maximum acceptable data loss (time since last backup)

| Tier | Service Type | RTO | RPO |
|------|-------------|-----|-----|
| Tier 1 | Payment, auth, core API | < 30 min | < 5 min |
| Tier 2 | User-facing features | < 2 hours | < 1 hour |
| Tier 3 | Internal tools, analytics | < 8 hours | < 24 hours |

---

## DR Scenario Matrix

| Scenario | Detection | Primary Response | Data Loss Risk |
|----------|-----------|-----------------|----------------|
| AZ failure | CloudWatch, ALB health | Multi-AZ failover (automatic) | Near zero |
| Region failure | AWS Health, all services down | DNS failover to secondary region | RPO-dependent |
| Data corruption | Data validation errors | Point-in-time restore | Since last backup |
| Accidental deletion | Missing resources | Restore from backup | Since last backup |
| Security breach | GuardDuty, unusual access | Isolate + forensics + restore | Varies |

---

## Pre-DR Preparation Checklist

Verify these exist BEFORE an incident:

```bash
# 1. Verify RDS automated backups are enabled
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,BackupRetention:BackupRetentionPeriod,BackupWindow:PreferredBackupWindow}' \
  --output table
# Expect: BackupRetention >= 7 days for Tier 1

# 2. Verify RDS Multi-AZ for Tier 1 services
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,MultiAZ:MultiAZ,Class:DBInstanceClass}' \
  --output table

# 3. Verify S3 versioning on critical buckets
aws s3api get-bucket-versioning --bucket my-critical-bucket
# Expect: {"Status": "Enabled"}

# 4. Verify Route53 health checks configured
aws route53 list-health-checks \
  --query 'HealthChecks[*].{ID:Id,Type:HealthCheckConfig.Type,Resource:HealthCheckConfig.FullyQualifiedDomainName}' \
  --output table

# 5. Verify secondary region has AMIs/images available
aws ec2 describe-images \
  --owners self \
  --region us-west-2 \
  --query 'Images[?CreationDate>`2025-01-01`].{ID:ImageId,Name:Name,Created:CreationDate}' \
  --output table | tail -5

# 6. Verify DR runbook is current (review quarterly)
```

---

## Scenario A: AZ Failure

**Expected behavior (if correctly architected):** Automatic.

```bash
# Verify Multi-AZ resources are failing over
# RDS: Automatic failover (~1-2 minutes for Multi-AZ)
aws rds describe-db-instances \
  --db-instance-identifier prod-db \
  --query 'DBInstances[0].{AZ:AvailabilityZone,SecondaryAZ:SecondaryAvailabilityZone,Status:DBInstanceStatus}'

# ECS/EKS: Tasks/pods reschedule to healthy AZs automatically
kubectl get pods -n production -o wide | grep -v Running

# ALB: Automatically routes to healthy AZs
aws elbv2 describe-target-health --target-group-arn ${TG_ARN}
```

**If NOT automatic (single-AZ):**
```bash
# Manually fail over RDS
aws rds reboot-db-instance \
  --db-instance-identifier prod-db \
  --force-failover

# Scale ECS service to trigger task replacement in healthy AZ
aws ecs update-service \
  --cluster production \
  --service my-service \
  --force-new-deployment
```

---

## Scenario B: Region Failure

**Pre-requisite:** Secondary region setup with Terraform, DNS failover routing policy.

```bash
# Step 1: Verify Route53 health check has tripped
aws route53 get-health-check-status \
  --health-check-id ${HEALTH_CHECK_ID}

# Step 2: If not automatic, manually update failover record
aws route53 change-resource-record-sets \
  --hosted-zone-id ${ZONE_ID} \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.example.com.",
        "Type": "A",
        "Failover": "PRIMARY",
        "HealthCheckId": "'${HEALTH_CHECK_ID}'",
        "SetIdentifier": "primary",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "secondary-region-alb.us-west-2.elb.amazonaws.com.",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'

# Step 3: Scale up secondary region ECS/EKS (if running cold)
aws ecs update-service \
  --cluster production-dr \
  --service my-service \
  --desired-count 3 \
  --region us-west-2

# Step 4: Verify RDS in secondary is up-to-date (if cross-region replica)
aws rds describe-db-instances \
  --db-instance-identifier prod-db-replica \
  --region us-west-2 \
  --query 'DBInstances[0].{Status:DBInstanceStatus,ReplicaLag:ReplicaLag}'

# Promote read replica to primary (IRREVERSIBLE — data diverges)
aws rds promote-read-replica \
  --db-instance-identifier prod-db-replica \
  --region us-west-2
```

---

## Scenario C: Data Corruption or Accidental Deletion

### RDS Point-in-Time Recovery (PITR)
```bash
# Determine restore time (when was data good?)
RESTORE_TIME="2026-02-25T10:00:00Z"  # 10 minutes before corruption

# Restore to new instance (non-destructive — existing DB unchanged)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-db \
  --target-db-instance-identifier prod-db-restored-$(date +%Y%m%d%H%M) \
  --restore-time ${RESTORE_TIME} \
  --db-instance-class db.r6g.xlarge \
  --vpc-security-group-ids ${SG_ID} \
  --db-subnet-group-name prod-subnet-group \
  --no-publicly-accessible

# Wait for restore (15-30 minutes typically)
aws rds wait db-instance-available \
  --db-instance-identifier prod-db-restored-$(date +%Y%m%d%H%M)

# Connect and verify data integrity
# Then: either update app connection string, or export specific data
```

### S3 Object Recovery (versioning required)
```bash
# List versions of deleted/overwritten object
aws s3api list-object-versions \
  --bucket my-bucket \
  --prefix path/to/file.json

# Restore by deleting the delete marker (undeletes the object)
aws s3api delete-object \
  --bucket my-bucket \
  --key path/to/file.json \
  --version-id $(aws s3api list-object-versions \
    --bucket my-bucket \
    --prefix path/to/file.json \
    --query 'DeleteMarkers[0].VersionId' --output text)
```

---

## Post-DR Validation

```bash
# 1. End-to-end health check
curl -f https://api.example.com/health
curl -f https://api.example.com/ready

# 2. Verify database data integrity
# Run application-specific data validation queries

# 3. Verify DNS is resolving to correct region
dig +short api.example.com
nslookup api.example.com

# 4. Verify application metrics are back to baseline
# Check error rate in Grafana/CloudWatch

# 5. Verify all services are running with expected replica counts
kubectl get deployments -n production
aws ecs describe-services --cluster production --query 'services[*].{Name:serviceName,Running:runningCount,Desired:desiredCount}'
```

## Post-DR Cleanup (after primary region recovers)

```bash
# 1. Verify primary region is fully healthy before switching back
# 2. Sync any data written to secondary back to primary
# 3. Gradual traffic shift back (10% → 50% → 100% over hours)
# 4. Update DNS to primary when confident
# 5. Delete temporary restored instances (don't leave running)
aws rds delete-db-instance \
  --db-instance-identifier prod-db-restored-TIMESTAMP \
  --skip-final-snapshot  # Only if data was already migrated
```

---
**Used by:** sre-engineer (DevOps pack), aws-cloud-engineer (DevOps pack)
**Related playbooks:** incident-response.md, rollback-strategy.md
