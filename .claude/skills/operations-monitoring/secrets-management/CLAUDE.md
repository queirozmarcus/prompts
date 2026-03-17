# Skill: Secrets Management

## Scope

Centralizes all best practices for managing secrets across the stack: creation, storage, injection, rotation, and scanning. Covers AWS Secrets Manager, SSM Parameter Store, HashiCorp Vault basics, secret injection in ECS/Kubernetes, automated rotation, and CI/CD pipeline secret scanning. Applies whenever secrets, credentials, API keys, or sensitive configuration are involved.

## Related Agent: security-ops (DevOps pack)
## Related Playbook: secret-rotation.md

## Core Principles

- **Secrets never in code or version control** — not in .env files committed, not in Dockerfiles, not in logs
- **Centralized secret store** — AWS Secrets Manager or Vault as single source of truth, never per-service config files
- **Least privilege access** — each service reads only the secrets it needs, via IAM roles (not shared credentials)
- **Rotation by design** — secrets have a lifespan; rotation is automated, not manual
- **Audit everything** — every secret access is logged; anomalies are alerted
- **No long-lived credentials** — prefer OIDC/instance roles over static access keys

## Secret Classification

| Type | Examples | Storage | Rotation |
|------|----------|---------|----------|
| **Tier 1: Critical** | DB master password, signing keys, CA certs | Secrets Manager with KMS | Automated, 30 days |
| **Tier 2: Service** | API keys, OAuth client secrets, service tokens | Secrets Manager or SSM SecureString | Automated, 90 days |
| **Tier 3: Config** | Feature flags, non-sensitive URLs, env names | SSM Parameter Store (plaintext) | On change only |

## AWS Secrets Manager

**Create and retrieve:**
```bash
# Create a secret
aws secretsmanager create-secret \
  --name "prod/myapp/db-password" \
  --description "Production database master password" \
  --secret-string "$(openssl rand -base64 32)" \
  --kms-key-id "arn:aws:kms:us-east-1:123456789:key/mrk-xxx"

# Retrieve (for debugging — never in scripts)
aws secretsmanager get-secret-value \
  --secret-id "prod/myapp/db-password" \
  --query 'SecretString' --output text

# Update a secret
aws secretsmanager put-secret-value \
  --secret-id "prod/myapp/db-password" \
  --secret-string '{"password":"newvalue","username":"admin"}'
```

**Naming convention:**
```
{environment}/{service}/{secret-name}
prod/payments-api/stripe-key
prod/api/db-credentials      # JSON: {"username":"...", "password":"..."}
staging/worker/redis-url
```

**IAM policy for a service to read its own secrets only:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/myapp/*"
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Decrypt"],
      "Resource": "arn:aws:kms:us-east-1:123456789:key/mrk-xxx",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

**Terraform resource:**
```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${local.name_prefix}/db-credentials"
  description = "Database credentials for ${var.service_name}"
  kms_key_id  = aws_kms_key.secrets.arn

  recovery_window_in_days = 7  # Deletion protection

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.secret_rotator.arn

  rotation_rules {
    automatically_after_days = 30
  }
}
```

## SSM Parameter Store

**When to use vs Secrets Manager:**
- SSM: Config values, feature flags, non-sensitive strings, cost-sensitive (free tier for standard params)
- Secrets Manager: Sensitive credentials requiring rotation, audit, cross-region replication

```bash
# Create SecureString parameter
aws ssm put-parameter \
  --name "/prod/myapp/api-key" \
  --value "sk_live_xxx" \
  --type SecureString \
  --key-id "arn:aws:kms:us-east-1:123456789:key/mrk-xxx" \
  --tier Standard

# Get parameter (decrypted)
aws ssm get-parameter \
  --name "/prod/myapp/api-key" \
  --with-decryption \
  --query 'Parameter.Value' --output text

# Get multiple parameters by path
aws ssm get-parameters-by-path \
  --path "/prod/myapp/" \
  --with-decryption \
  --recursive
```

**Terraform:**
```hcl
data "aws_ssm_parameter" "db_url" {
  name            = "/prod/myapp/db-url"
  with_decryption = true
}

# Reference in ECS task definition
environment {
  name  = "DATABASE_URL"
  value = data.aws_ssm_parameter.db_url.value  # Avoid: resolved at plan time
}

# Better: use secrets block for runtime resolution
secrets {
  name      = "DATABASE_URL"
  valueFrom = data.aws_ssm_parameter.db_url.arn
}
```

## Secret Injection at Runtime

### ECS (Fargate/EC2)

```json
{
  "containerDefinitions": [{
    "name": "api",
    "secrets": [
      {
        "name": "DATABASE_URL",
        "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/api/db-credentials:database_url::"
      },
      {
        "name": "STRIPE_KEY",
        "valueFrom": "arn:aws:ssm:us-east-1:123456789:parameter/prod/api/stripe-key"
      }
    ]
  }]
}
```

ECS retrieves secrets at container start and injects as environment variables. The task execution role needs `secretsmanager:GetSecretValue` and `ssm:GetParameters`.

### Kubernetes (External Secrets Operator)

```yaml
# ExternalSecret — syncs from Secrets Manager to K8s Secret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: api-credentials   # K8s Secret name
    creationPolicy: Owner
  data:
    - secretKey: DATABASE_URL
      remoteRef:
        key: prod/api/db-credentials
        property: database_url
    - secretKey: STRIPE_KEY
      remoteRef:
        key: prod/api/stripe-key
---
# Use in Pod
envFrom:
  - secretRef:
      name: api-credentials
```

**Never use hardcoded secrets in K8s manifests — even base64-encoded secrets are not encrypted.**

### Application Layer (sidecar pattern)

```python
import boto3
import json
from functools import lru_cache

@lru_cache(maxsize=None)
def get_secret(secret_name: str) -> dict:
    """Retrieve and cache secret. Cache survives process lifetime."""
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

# Usage
creds = get_secret("prod/api/db-credentials")
DATABASE_URL = f"postgresql://{creds['username']}:{creds['password']}@{creds['host']}/db"
```

## Automated Rotation

**Rotation Lambda pattern (dual-credentials):**
```
Phase 1: createSecret   — Create new password, store as AWSPENDING
Phase 2: setSecret      — Set new password on the target service (DB, API, etc.)
Phase 3: testSecret     — Verify new password works
Phase 4: finishSecret   — Promote AWSPENDING → AWSCURRENT; old becomes AWSPREVIOUS
```

**Built-in rotators** (no Lambda needed):
- RDS MySQL/PostgreSQL/Oracle/SQL Server — use `SecretsManager-RDS-*` Lambda
- DocumentDB, Redshift — native rotation support

```bash
# Trigger manual rotation (for testing)
aws secretsmanager rotate-secret \
  --secret-id "prod/api/db-credentials" \
  --rotate-immediately

# Check rotation status
aws secretsmanager describe-secret \
  --secret-id "prod/api/db-credentials" \
  --query '{LastRotatedDate:LastRotatedDate,NextRotationDate:NextRotationDate,RotationEnabled:RotationEnabled}'
```

## Secret Scanning (Pipeline Gates)

**Pre-commit (prevent committing secrets):**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

**CI pipeline gate:**
```yaml
# GitHub Actions
- name: Scan for secrets
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}

- name: Detect secrets (detect-secrets)
  run: |
    pip install detect-secrets
    detect-secrets scan --baseline .secrets.baseline
    detect-secrets audit .secrets.baseline
```

**GitHub Advanced Security (GHAS) — push protection:**
```yaml
# Enable in repository settings → Security → Secret scanning
# Push protection blocks pushes with detected secrets automatically
# Covers 200+ secret patterns from providers like AWS, GitHub, Stripe
```

**Scan git history for leaked secrets:**
```bash
# Scan entire repository history
gitleaks detect --source . --config .gitleaks.toml --exit-code 1

# If secrets found in history — rotate immediately, then remove
git filter-repo --path-glob '**/*.env' --invert-paths  # Remove file from history
# Or: use BFG Repo Cleaner for large repos
bfg --delete-files .env
```

## HashiCorp Vault (Basics)

**When to use Vault vs Secrets Manager:**
- Vault: Multi-cloud, on-premises, dynamic secrets, complex policies
- Secrets Manager: AWS-only, simpler ops, native AWS service integration

**Dynamic secrets (Vault's key advantage):**
```bash
# Vault generates short-lived DB credentials on demand
vault read database/creds/readonly-role
# Returns: lease_duration=1h, username="v-token-xxx", password="auto-generated"
# Credentials auto-expire; no manual rotation needed
```

**Kubernetes auth with Vault:**
```yaml
# ServiceAccount bound to Vault policy
vault write auth/kubernetes/role/api \
  bound_service_account_names=api \
  bound_service_account_namespaces=production \
  policies=api-policy \
  ttl=1h
```

## What to Avoid

- **`.env` files in version control** — `.gitignore` should include all `.env*` patterns
- **Secrets in environment variables at build time** — they end up in image layers
- **Shared service accounts** — each service gets its own credential
- **Secrets in CI/CD logs** — mask all secrets; never `echo $SECRET`
- **Hardcoded in Terraform** — use `sensitive = true` on variables; use data sources for existing secrets
- **Long-lived AWS access keys** — use OIDC/instance profiles; rotate immediately if keys are static

## Communication Style

When this skill is active:
- Always ask: "Where does this secret live? Who retrieves it, and how?"
- Provide IAM policies alongside secret creation steps
- Highlight dual-credential rotation strategy for zero-downtime secret changes
- Flag any pattern that risks secret exposure in logs, history, or plaintext storage
- Remind: rotate compromised secrets before removing from history

## Expected Output Quality

- IAM policies scoped to the specific secret ARN (never wildcards)
- Terraform resources with KMS encryption and `recovery_window_in_days`
- ECS/K8s injection patterns (never hardcoded values in manifests)
- CI/CD pipeline steps for secret scanning as gates (not advisory)

---
**Skill type:** Passive
**Applies with:** security, aws, docker-security, kubernetes, terraform
**Pairs well with:** security-ops (DevOps pack), architect (Dev pack)
