# Playbook: Terraform Plan & Apply

## Inputs Required

Before starting, confirm:
- [ ] `ENVIRONMENT` — which environment? (production/staging/dev)
- [ ] `WORKING_DIR` — path to terraform config (`environments/production/`)
- [ ] `TARGET` — specific resource to target? (or full apply)
- [ ] `VAR_FILE` — environment-specific var file path
- [ ] `APPROVED_BY` — who approved this change?

## Pre-Flight Checks

```bash
# 1. Verify AWS credentials and correct account
aws sts get-caller-identity
# Confirm: Account ID matches expected, not wrong environment!

# 2. Check state is not locked
aws dynamodb get-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "my-bucket/production/terraform.tfstate"}}' \
  --query 'Item'
# If locked: check who locked it before force-unlocking

# 3. Backend connectivity
terraform init
# Confirm: "Backend reinitialized. No previous state found." or "Initialized successfully"

# 4. Check for pending changes in state
git log --oneline -5
git status  # Ensure working on latest main
```

## Validation Pipeline

```bash
# Run all checks sequentially — stop on first failure
set -e

# Step 1: Format check
echo "==> Checking format..."
terraform fmt -check -recursive
echo "✓ Format OK"

# Step 2: Validate syntax and references
echo "==> Validating..."
terraform validate
echo "✓ Validate OK"

# Step 3: Lint (AWS-specific rules)
echo "==> Linting..."
tflint --recursive --config .tflint.hcl
echo "✓ Lint OK"

# Step 4: Security scan
echo "==> Security scan..."
checkov -d . --framework terraform --compact --quiet \
  --output-file-path ./checkov-results \
  --soft-fail-on MEDIUM  # Only fail on HIGH/CRITICAL
echo "✓ Security scan OK"

# Step 5: Cost estimate (requires Infracost CLI)
echo "==> Cost estimate..."
infracost diff --path . --compare-to main --format table
# Note: Review this output before proceeding
```

## Generate and Review Plan

```bash
# Generate plan (save to binary file for deterministic apply)
terraform plan \
  -out=tfplan.binary \
  -no-color \
  -var-file=terraform.tfvars \
  | tee tfplan.txt

# Human-readable analysis
echo "==> Resources to be destroyed:"
terraform show -json tfplan.binary | \
  jq -r '.resource_changes[] | select(.change.actions | contains(["delete"])) | "  DESTROY: \(.address)"'

echo "==> Resources to be created:"
terraform show -json tfplan.binary | \
  jq -r '.resource_changes[] | select(.change.actions | contains(["create"])) | "  CREATE: \(.address)"'

echo "==> Force-replace (destroy + create):"
terraform show -json tfplan.binary | \
  jq -r '.resource_changes[] | select(.change.actions == ["delete","create"]) | "  REPLACE: \(.address)"'
```

## Plan Review Checklist

Before approving apply:

**Destruction gate:**
- [ ] Are there any `-/+ destroy and recreate` resources?
- [ ] Are there any `destroy` operations?
- [ ] If yes to above: are these expected? is data preserved (snapshots/backups)?

**Critical resources check:**
- [ ] Any RDS instance modifications? (May cause brief downtime for some changes)
- [ ] Any security group changes? (May impact access to running services)
- [ ] Any IAM role/policy changes? (Review for least privilege)
- [ ] Any VPC/subnet/route table changes? (May break routing)

**Security review:**
- [ ] No wildcard `*` added to IAM policies
- [ ] No S3 bucket policy allowing `*` Principal
- [ ] No security group rule with `0.0.0.0/0` on sensitive ports (22, 3389, DB ports)
- [ ] No encryption disabled on storage resources
- [ ] Required tags present on new resources

**Cost impact:**
- [ ] Infracost diff reviewed
- [ ] Any new NAT Gateways? ($0.045/hr + $0.045/GB — significant)
- [ ] RDS class change? (Price difference calculated)
- [ ] New CloudWatch Log Groups? (Retention policy configured?)

**Approval gate:**
- If DESTROY operations on production critical resources: **STOP — escalate**
- If cost increase > $100/month: **document justification**
- If IAM policy changes: **second reviewer required**

## Apply

```bash
# ONLY after plan review checklist complete and approval obtained
echo "Applying plan — approved by: ${APPROVED_BY}"
echo "Environment: ${ENVIRONMENT}"
echo "Timestamp: $(date -u)"

# Apply the saved plan (deterministic — no re-evaluation)
terraform apply tfplan.binary

# Monitor for errors during apply
# If apply fails mid-way: DO NOT retry blindly
# Run terraform plan again to see current state vs desired
```

## Post-Apply Validation

```bash
# 1. Verify outputs
terraform output

# 2. Verify specific resources (examples)
# For new ECS service:
aws ecs describe-services \
  --cluster ${CLUSTER} \
  --services ${SERVICE_NAME} \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# For new RDS instance:
aws rds describe-db-instances \
  --db-instance-identifier ${DB_ID} \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Class:DBInstanceClass,MultiAZ:MultiAZ}'

# For new security group rules:
aws ec2 describe-security-groups --group-ids ${SG_ID} \
  --query 'SecurityGroups[0].IpPermissions'

# 3. Application smoke test (if applicable)
# Run service health check or integration test suite
```

## Rollback Options

**Option A: Revert code and re-apply (preferred)**
```bash
git revert HEAD --no-edit
git push origin main
# Trigger CI/CD pipeline to apply reverted state
```

**Option B: Targeted apply of previous state**
```bash
# Roll back specific resource to previous configuration
git diff HEAD~1 -- environments/production/main.tf
# Cherry-pick the specific resource block from previous version
terraform apply -target=aws_ecs_service.myapp
```

**Option C: State manipulation (last resort)**
```bash
# Remove resource from state (does NOT delete in AWS)
terraform state rm aws_resource.name
# Re-import previous version
terraform import aws_resource.name <resource-id>
```

**Rollback is NOT possible for:**
- RDS instance deletion (if no snapshot taken pre-apply)
- S3 bucket deletion (if not versioned)
- KMS key deletion (24-30 day waiting period)

## State Cleanup

```bash
# Verify state is clean after apply
terraform plan
# Expected: "No changes. Your infrastructure matches the configuration."

# Clean up local plan files
rm -f tfplan.binary tfplan.txt checkov-results/
```

---
**Used by:** iac-engineer (DevOps pack)
**Related playbooks:** rollback-strategy.md, security-audit.md
