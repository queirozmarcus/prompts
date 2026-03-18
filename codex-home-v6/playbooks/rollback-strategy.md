# Playbook: Rollback Strategy

## Decision Framework: Rollback vs Roll Forward

**Roll back when:**
- Bug or regression introduced by the deploy is causing user impact
- Root cause is known and in the deployed artifact
- Previous version is known-good
- Rollback is faster than a hotfix deploy

**Roll forward when:**
- A data migration has already run (rolling back causes inconsistency)
- The issue exists in both old and new versions
- A hotfix is ready and can be deployed in < 15 minutes
- Rolling back would break another recently deployed service dependency

**Always:**
1. Stabilize first (rollback)
2. Understand second (root cause)
3. Exception: if rollback would cause data loss — stabilize another way first

---

## Terraform Rollback

### Option A: Revert commit and re-apply (preferred)
```bash
# Revert the commit that caused the issue
git revert HEAD --no-edit
git push origin main

# CI/CD pipeline runs plan + apply on main
# OR apply manually:
git pull
cd environments/production
terraform plan -out=tfplan.binary
terraform apply tfplan.binary
```

### Option B: Target-apply previous configuration
```bash
# If only one resource changed, apply just that resource to previous value
terraform plan -target=aws_ecs_service.myapp -out=tfplan.binary
terraform apply tfplan.binary
```

### Option C: State manipulation (destructive — last resort)
```bash
# Remove a resource from state (does NOT delete in AWS)
terraform state rm aws_resource.problem_resource

# Re-import the previous known-good resource version
terraform import aws_resource.problem_resource <resource-id>

# Apply to reconcile
terraform apply
```

### Terraform cannot roll back:
- Deleted S3 buckets (if no versioning, data is gone)
- Deleted RDS instances (if no snapshot taken before)
- KMS key deletion (24-30 day deletion waiting period — cancel quickly)
- Removed IAM policies (re-add from previous version)

---

## Kubernetes Rollback

### Standard rollback (Deployment)
```bash
# Immediate rollback to previous ReplicaSet
kubectl rollout undo deployment/${DEPLOYMENT} -n ${NAMESPACE}

# Monitor rollback
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE} --timeout=5m

# Verify correct image is running
kubectl get deployment/${DEPLOYMENT} -n ${NAMESPACE} \
  -o jsonpath='{.spec.template.spec.containers[0].image}'

# Rollback to specific revision
kubectl rollout history deployment/${DEPLOYMENT} -n ${NAMESPACE}
kubectl rollout undo deployment/${DEPLOYMENT} --to-revision=3 -n ${NAMESPACE}
```

### ArgoCD rollback (GitOps — preferred)
```bash
# View history
argocd app history ${APP_NAME}-production

# Rollback to specific deployment ID
argocd app rollback ${APP_NAME}-production <HISTORY_ID>

# Monitor rollback
argocd app wait ${APP_NAME}-production --health --timeout 300
```

### StatefulSet rollback (with care — pods have persistent storage)
```bash
# StatefulSets don't have rollout undo — update the image directly
kubectl set image statefulset/${STS_NAME} ${CONTAINER}=${PREVIOUS_IMAGE} -n ${NAMESPACE}

# Monitor ordered rollout (StatefulSets update pods in reverse order)
kubectl rollout status statefulset/${STS_NAME} -n ${NAMESPACE} --timeout=10m
```

---

## Application Rollback (ECS)

```bash
# ECS: Force new deployment with previous task definition
PREVIOUS_REVISION=$(($(aws ecs describe-services \
  --cluster production \
  --services my-service \
  --query 'services[0].taskDefinition' \
  --output text | grep -oP '\d+$') - 1))

aws ecs update-service \
  --cluster production \
  --service my-service \
  --task-definition my-task:${PREVIOUS_REVISION} \
  --force-new-deployment

# Monitor
aws ecs wait services-stable --cluster production --services my-service
```

---

## Feature Flag Rollback

```bash
# Fastest rollback — no deploy needed
# Disable feature via SSM Parameter Store
aws ssm put-parameter \
  --name "/production/features/new-checkout-flow" \
  --value "false" \
  --overwrite

# Verify flag took effect (depends on app polling interval)
aws ssm get-parameter --name "/production/features/new-checkout-flow"
```

---

## Database Migration Rollback

### Rollback with down migration
```bash
# Most ORMs support down migrations
# Node.js with node-pg-migrate:
npm run migrate down

# Sequelize
npx sequelize-cli db:migrate:undo

# Flyway
flyway undo  # Requires Flyway Teams/Enterprise
```

### RDS Point-in-Time Recovery (if data was corrupted/deleted)
```bash
# Restore to 5 minutes before the incident
RESTORE_TIME=$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)

aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-db \
  --target-db-instance-identifier prod-db-restored-$(date +%Y%m%d-%H%M) \
  --restore-time ${RESTORE_TIME} \
  --db-instance-class db.r6g.xlarge \
  --no-multi-az  # Single-AZ for temporary restore

# Monitor restore status
aws rds wait db-instance-available \
  --db-instance-identifier prod-db-restored-$(date +%Y%m%d-%H%M)

# Update application connection string to point to restored instance
# (or promote via renaming after validation)
```

### Zero-downtime migration strategy
```sql
-- 1. Add new column (non-breaking)
ALTER TABLE orders ADD COLUMN new_status VARCHAR(50);

-- 2. Deploy code that writes to both old and new column
-- 3. Backfill new column
UPDATE orders SET new_status = status WHERE new_status IS NULL;

-- 4. Deploy code that reads from new column
-- 5. Drop old column (in a separate deployment, after rollback window passes)
ALTER TABLE orders DROP COLUMN status;
```

---

## DNS Rollback

```bash
# Route53: Revert to previous record value
# Get current record
aws route53 list-resource-record-sets \
  --hosted-zone-id ${ZONE_ID} \
  --query "ResourceRecordSets[?Name=='api.example.com.']"

# Update record back to previous IP/ALB
cat > dns-rollback.json <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "api.example.com.",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z35SXDOTRQ7X7K",
        "DNSName": "previous-alb.us-east-1.elb.amazonaws.com.",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id ${ZONE_ID} \
  --change-batch file://dns-rollback.json

# DNS propagation: 30-300 seconds depending on TTL
```

---
**Used by:** terraform-infra-agent, k8s-platform-agent, gitops-agent, incident-agent
**Related playbooks:** incident-response.md, terraform-plan-apply.md, k8s-deploy-safe.md
