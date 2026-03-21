# Playbook: Secret Rotation

## Purpose

Zero-downtime rotation of secrets for production services. Covers audit of active secrets, dual-credential rotation strategy (prevents downtime during rotation), updating consumers (ECS tasks, Kubernetes pods), validating the new secret, and decommissioning the old one.

## Inputs

- [ ] `SECRET_ID` — AWS Secrets Manager ARN or name (e.g., `prod/api/db-credentials`)
- [ ] `SERVICE_NAME` — service(s) consuming this secret
- [ ] `ROTATION_TYPE` — database | api-key | token | certificate
- [ ] `ENVIRONMENT` — staging | production

---

## Phase 0: Secret Inventory Audit

Before rotating, establish what secrets exist, who owns them, and when they last rotated.

```bash
# List all secrets in the account with last rotation date
aws secretsmanager list-secrets \
  --query 'SecretList[*].{Name:Name,LastRotated:LastRotatedDate,RotationEnabled:RotationEnabled,NextRotation:NextRotationDate}' \
  --output table

# Find secrets NOT rotated in the last 90 days
aws secretsmanager list-secrets \
  --query "SecretList[?LastRotatedDate < '$(date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%S)'].{Name:Name,LastRotated:LastRotatedDate}" \
  --output table

# Find secrets with rotation DISABLED
aws secretsmanager list-secrets \
  --query "SecretList[?RotationEnabled == \`false\`].{Name:Name,Created:CreatedDate}" \
  --output table

# Get details for specific secret
aws secretsmanager describe-secret \
  --secret-id "${SECRET_ID}" \
  --query '{Name:Name,ARN:ARN,RotationEnabled:RotationEnabled,LastRotated:LastRotatedDate,VersionsToStages:VersionIdsToStages}'
```

---

## Phase 1: Dual-Credential Strategy (Zero-Downtime)

**Why dual-credential rotation:**
- If you delete the old credential before all consumers restart with the new one, requests fail
- Dual-credential keeps BOTH old and new valid during the transition window

```
ROTATION PHASES:
┌─────────────────────────────────────────────────────────┐
│  Phase 1: CREATE NEW        ┌──────────────┐            │
│  Old cred = AWSCURRENT  →   │ New cred     │ AWSPENDING │
│  New cred = AWSPENDING      └──────────────┘            │
│  Both valid on the service                              │
├─────────────────────────────────────────────────────────┤
│  Phase 2: TEST NEW                                       │
│  Verify new credential works before promoting           │
├─────────────────────────────────────────────────────────┤
│  Phase 3: PROMOTE NEW                                    │
│  New cred = AWSCURRENT                                  │
│  Old cred = AWSPREVIOUS (still valid, grace period)     │
├─────────────────────────────────────────────────────────┤
│  Phase 4: CONSUMERS UPDATE                               │
│  Trigger ECS redeployment / K8s secret refresh          │
│  Consumers pick up AWSCURRENT                           │
├─────────────────────────────────────────────────────────┤
│  Phase 5: REVOKE OLD                                     │
│  After all consumers confirmed updated:                 │
│  Remove AWSPREVIOUS from the service                    │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 2: Rotation by Type

### Database Credentials (RDS PostgreSQL)

```bash
# Enable automated rotation with RDS rotation Lambda
aws secretsmanager rotate-secret \
  --secret-id "${SECRET_ID}" \
  --rotation-lambda-arn "arn:aws:lambda:us-east-1:123456789:function:SecretsManagerRDSPostgreSQLRotation" \
  --rotation-rules AutomaticallyAfterDays=30

# Manual rotation trigger (for immediate rotation)
aws secretsmanager rotate-secret \
  --secret-id "${SECRET_ID}" \
  --rotate-immediately

# Monitor rotation status
aws secretsmanager describe-secret \
  --secret-id "${SECRET_ID}" \
  --query '{Stage:VersionIdsToStages,LastRotated:LastRotatedDate,RotationStatus:RotationEnabled}'
```

**Manual rotation (if automated rotation is not available):**
```bash
# Step 1: Generate new password
NEW_PASSWORD=$(openssl rand -base64 32 | tr -dc '[:alnum:]' | head -c 32)

# Step 2: Create new DB user with same permissions (dual-user strategy)
psql -h ${DB_HOST} -U admin ${DB_NAME} << EOF
CREATE USER ${SERVICE_USER}_v2 WITH PASSWORD '${NEW_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${SERVICE_USER}_v2;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${SERVICE_USER}_v2;
EOF

# Step 3: Update secret to new user credentials
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_ID}" \
  --secret-string "{\"username\":\"${SERVICE_USER}_v2\",\"password\":\"${NEW_PASSWORD}\",\"host\":\"${DB_HOST}\",\"dbname\":\"${DB_NAME}\"}"
```

### API Keys / Tokens

```bash
# Pattern: Create new key at the provider, store as AWSPENDING, then promote

# Step 1: Generate new API key at provider (provider-specific)
# e.g., for Stripe:
NEW_KEY=$(stripe api-keys create --type restricted --name "prod-service-$(date +%Y%m)" --query 'secret' --output text)

# Step 2: Store as AWSPENDING version
aws secretsmanager put-secret-value \
  --secret-id "${SECRET_ID}" \
  --secret-string "${NEW_KEY}" \
  --version-stages AWSPENDING

# Step 3: Test new key (validation step — see Phase 3)

# Step 4: Promote AWSPENDING to AWSCURRENT
aws secretsmanager update-secret-version-stage \
  --secret-id "${SECRET_ID}" \
  --version-stage AWSCURRENT \
  --move-to-version-id $(aws secretsmanager list-secret-version-ids \
    --secret-id "${SECRET_ID}" \
    --query 'Versions[?VersionStages[?contains(@,`AWSPENDING`)]].VersionId' \
    --output text)
```

---

## Phase 3: Validate New Secret

```bash
# Test the AWSPENDING (new) credential before promoting
NEW_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ID}" \
  --version-stage AWSPENDING \
  --query 'SecretString' --output text)

# For database: test connection with new credentials
NEW_USER=$(echo $NEW_SECRET | jq -r '.username')
NEW_PASS=$(echo $NEW_SECRET | jq -r '.password')
DB_HOST=$(echo $NEW_SECRET | jq -r '.host')
DB_NAME=$(echo $NEW_SECRET | jq -r '.dbname')

psql "postgresql://${NEW_USER}:${NEW_PASS}@${DB_HOST}/${DB_NAME}" \
  -c "SELECT current_user, current_database();" \
  && echo "✅ New credential VALID" \
  || echo "❌ New credential INVALID — DO NOT PROMOTE"
```

---

## Phase 4: Update Consumers

### ECS Service (force new deployment to pick up new secret)

```bash
# ECS reads secrets at container startup from Secrets Manager
# Force redeployment to get new secret version

aws ecs update-service \
  --cluster production \
  --service "${SERVICE_NAME}" \
  --force-new-deployment

# Monitor rollout
aws ecs wait services-stable \
  --cluster production \
  --services "${SERVICE_NAME}"

echo "ECS service updated"

# Verify new tasks are using new secret version
aws ecs describe-tasks \
  --cluster production \
  --tasks $(aws ecs list-tasks --cluster production --service-name "${SERVICE_NAME}" --query 'taskArns[0]' --output text) \
  --query 'tasks[0].startedAt'
```

### Kubernetes (External Secrets Operator)

```bash
# External Secrets Operator syncs automatically on refresh interval
# Force immediate sync:
kubectl annotate externalsecret "${SERVICE_NAME}-credentials" \
  --namespace production \
  force-sync="$(date +%s)" --overwrite

# Wait for secret to sync
kubectl get externalsecret "${SERVICE_NAME}-credentials" \
  --namespace production \
  --watch

# Restart deployment to pick up new secret values
kubectl rollout restart deployment/"${SERVICE_NAME}" --namespace production
kubectl rollout status deployment/"${SERVICE_NAME}" --namespace production --timeout=5m
```

### Application Restart Notification

```bash
# Notify relevant teams of rotation and restart
echo "=== Secret Rotation: Consumer Update ==="
echo "Secret: ${SECRET_ID}"
echo "Service: ${SERVICE_NAME}"
echo "Time: $(date -u)"
echo "Action: Force redeployment initiated"
echo "Expected downtime: 0 (zero-downtime rotation)"
echo ""
echo "Monitor: https://grafana.example.com/d/service-health?var-service=${SERVICE_NAME}"
```

---

## Phase 5: Validate Service Health Post-Rotation

```bash
# Check service health immediately after redeployment
sleep 60  # Wait for new tasks to stabilize

# Application health check
curl -sf https://api.example.com/health \
  && echo "✅ Health check PASSED" \
  || echo "❌ Health check FAILED — initiate rollback"

# Check error rate (5-minute window)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=${ALB_ARN_SUFFIX} \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Sum --output table

# Check application logs for authentication errors
aws logs start-query \
  --log-group-name /aws/ecs/${SERVICE_NAME} \
  --start-time $(date -d '10 minutes ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /auth|credential|password|forbidden|401|403/ | sort @timestamp desc | limit 20'
```

---

## Phase 6: Decommission Old Credential

**Only after confirming all consumers are using the new credential:**

```bash
# For database: remove old user (dual-user rotation)
psql -h ${DB_HOST} -U admin ${DB_NAME} << EOF
-- Verify no active connections from old user
SELECT count(*) FROM pg_stat_activity WHERE usename = '${SERVICE_USER}';

-- If count = 0, drop old user
DROP USER ${SERVICE_USER};
EOF

# For Secrets Manager: old version is automatically cleaned up
# Verify AWSPREVIOUS is removed after all consumers updated:
aws secretsmanager list-secret-version-ids \
  --secret-id "${SECRET_ID}" \
  --query 'Versions[*].{ID:VersionId,Stages:VersionStages}'
```

---

## Rollback Procedure

**If new credential causes failures:**

```bash
# Option 1: Revert to AWSPREVIOUS in Secrets Manager
PREVIOUS_VERSION=$(aws secretsmanager list-secret-version-ids \
  --secret-id "${SECRET_ID}" \
  --query 'Versions[?VersionStages[?contains(@,`AWSPREVIOUS`)]].VersionId' \
  --output text)

aws secretsmanager update-secret-version-stage \
  --secret-id "${SECRET_ID}" \
  --version-stage AWSCURRENT \
  --move-to-version-id "${PREVIOUS_VERSION}"

# Option 2: Force redeployment with previous secret version
# ECS will pick up AWSCURRENT (now reverted to old value)
aws ecs update-service \
  --cluster production \
  --service "${SERVICE_NAME}" \
  --force-new-deployment
```

---

## Rotation Summary Report

```
=== Secret Rotation Summary ===
Date: $(date -u)
Secret: ${SECRET_ID}
Service: ${SERVICE_NAME}
Rotation Type: ${ROTATION_TYPE}
Environment: ${ENVIRONMENT}

Phases Completed:
  Pre-rotation audit:       [ PASS ]
  New credential created:   [ PASS ]
  New credential validated: [ PASS ]
  Consumers updated:        [ PASS / PARTIAL ]
  Service health confirmed: [ PASS ]
  Old credential revoked:   [ PASS / PENDING ]

Next rotation due: $(date -u -d '30 days')
Automated rotation: [ ENABLED / DISABLED ]
```

---
**Used by:** security-ops (DevOps pack)
**Related playbooks:** security-audit.md, dr-restore.md
**Related skills:** secrets-management
