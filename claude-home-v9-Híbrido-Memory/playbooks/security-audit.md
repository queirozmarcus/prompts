# Playbook: Security Audit

## Purpose

Pre-deployment security gate checklist. Run before any production deployment. Catches secrets, vulnerabilities, insecure configurations, and compliance violations before they reach production.

## Inputs

- [ ] `CODE_DIR` — source code directory to scan
- [ ] `IMAGE` — Docker image to scan (if applicable)
- [ ] `TERRAFORM_DIR` — IaC directory (if applicable)

---

## 1. Secrets Scanning

```bash
# detect-secrets (Python) — prevents committing new secrets
pip install detect-secrets
detect-secrets scan ${CODE_DIR} --baseline .secrets.baseline

# Audit existing baseline (review any flagged items)
detect-secrets audit .secrets.baseline

# gitleaks — scan git history for secrets (catches old commits too)
gitleaks detect \
  --source ${CODE_DIR} \
  --config .gitleaks.toml \
  --exit-code 1

# git-secrets (AWS patterns)
git secrets --scan
```

**Gate:** Any detected secret = BLOCK. No exceptions.

---

## 2. SAST (Static Application Security Testing)

```bash
# Semgrep — OWASP Top 10, injection, crypto misuse
semgrep scan \
  --config p/owasp-top-ten \
  --config p/nodejs \
  --config p/secrets \
  --error \
  ${CODE_DIR}

# GitHub CodeQL (if in CI pipeline)
# Configured in .github/workflows/codeql.yml
# Reports to GitHub Security tab
```

**GitHub Advanced Security (GHAS) integration:**
```yaml
# .github/workflows/codeql.yml
name: CodeQL Analysis
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 8 * * 1'  # Weekly full scan

permissions:
  security-events: write
  actions: read
  contents: read

jobs:
  analyze:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        language: [javascript, python]  # Add java if applicable
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          queries: security-and-quality
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with:
          category: /language:${{ matrix.language }}

# Enable GHAS secret scanning push protection in repository settings:
# Settings → Security → Secret scanning → Enable push protection
# This blocks pushes containing detected secrets BEFORE they land in history
```

**Severity gate (explicit thresholds):**
| Severity | Action | SLA |
|---------|--------|-----|
| **CRITICAL** | **BLOCK deployment** — fix before merging | Immediate |
| **HIGH** | **BLOCK PR merge** — fix within current sprint | 7 days |
| **MEDIUM** | Document with remediation date; escalate to security team | 30 days |
| **LOW** | Add to security tech debt backlog | 90 days |
| **INFO** | No action required; optional improvement | — |

**Exception process:** Any CRITICAL/HIGH requiring a waiver must have written justification, security team sign-off, and an expiry date (max 30 days).

---

## 3. Dependency Vulnerability Scan (SCA)

```bash
# Node.js
npm audit --audit-level=high        # Fails on high+ severity
npm audit --json | jq '.vulnerabilities | to_entries[] | select(.value.severity == "critical" or .value.severity == "high")'

# Python
pip-audit --requirement requirements.txt --severity high

# Java
mvn org.owasp:dependency-check-maven:check -DfailBuildOnCVSS=7

# Docker image dependency scan (handled in step 5)
```

**Gate:** HIGH or CRITICAL severity = BLOCK (unless a documented exception with expiry date exists).

---

## 4. IaC Security Scan (Terraform / CloudFormation / Kubernetes)

```bash
# Checkov — comprehensive IaC scanner
checkov -d ${TERRAFORM_DIR} \
  --framework terraform \
  --compact \
  --quiet \
  --output cli \
  --output sarif \
  --output-file-path checkov-results \
  --soft-fail-on MEDIUM  # Only fail on HIGH/CRITICAL

# Review failures
checkov -d ${TERRAFORM_DIR} --list  # List all available checks

# tfsec (Terraform-specific)
tfsec ${TERRAFORM_DIR} \
  --severity HIGH \
  --format sarif \
  --out tfsec-results.sarif

# Kubernetes manifests
checkov -d k8s/ --framework kubernetes

# Common HIGH/CRITICAL findings to check:
# - S3 bucket public access enabled
# - Security group 0.0.0.0/0 on privileged ports
# - IAM wildcard (*) in policies
# - RDS without encryption
# - EBS volume without encryption
# - No MFA on IAM users/root
```

**Gate:** HIGH/CRITICAL checkov findings = BLOCK.

---

## 5. Container Image Scanning

```bash
# Trivy — comprehensive container scanner
trivy image \
  --exit-code 1 \
  --severity CRITICAL,HIGH \
  --ignore-unfixed \
  --format table \
  ${IMAGE}

# Trivy with SARIF output for GitHub Security tab
trivy image \
  --format sarif \
  --output trivy-results.sarif \
  ${IMAGE}

# Grype (Anchore) — alternative scanner for second opinion
grype ${IMAGE} \
  --fail-on high \
  -o table

# Check for secrets in image layers
trivy image \
  --scanners secret \
  ${IMAGE}
```

**Gate:**
- CRITICAL CVEs = BLOCK (no exceptions)
- HIGH CVEs = BLOCK unless documented exception with expiry date

---

## 6. IAM Policy Review

```bash
# List all inline and attached policies for a role
aws iam list-role-policies --role-name my-service-role
aws iam list-attached-role-policies --role-name my-service-role

# Review policy for wildcard actions
aws iam get-role-policy --role-name my-service-role --policy-name my-policy \
  | jq '.PolicyDocument.Statement[] | select(.Action | contains("*"))'

# Review policy for wildcard resources
aws iam get-role-policy --role-name my-service-role --policy-name my-policy \
  | jq '.PolicyDocument.Statement[] | select(.Resource == "*" or (.Resource | type == "array" and contains(["*"])))'

# IAM Access Analyzer — find unused permissions
aws accessanalyzer list-findings \
  --analyzer-arn ${ANALYZER_ARN} \
  --filter '{"resourceType":{"eq":["AWS::IAM::Role"]}}'
```

**IAM checklist:**
- [ ] No wildcard `*` in Action field (unless justified and documented)
- [ ] No `Resource: "*"` unless specifically required (e.g., CloudWatch Logs CreateLogGroup)
- [ ] Role used only by the intended service (not shared)
- [ ] No `PassRole` to more privileged roles without boundary
- [ ] IRSA roles use condition on namespace/serviceaccount

---

## 7. Network Exposure Review

```bash
# Find security groups with 0.0.0.0/0 inbound
aws ec2 describe-security-groups \
  --query 'SecurityGroups[?IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`] || Ipv6Ranges[?CidrIpv6==`::/0`]]].{ID:GroupId,Name:GroupName,Ports:IpPermissions[*].FromPort}' \
  --output table

# Find RDS instances publicly accessible
aws rds describe-db-instances \
  --query 'DBInstances[?PubliclyAccessible==`true`].{ID:DBInstanceIdentifier,Endpoint:Endpoint.Address}' \
  --output table

# Find S3 buckets with public access allowed
aws s3api list-buckets --query 'Buckets[*].Name' --output text | tr '\t' '\n' | \
  while read bucket; do
    STATUS=$(aws s3api get-public-access-block --bucket "$bucket" 2>/dev/null \
      | jq '.PublicAccessBlockConfiguration | .BlockPublicAcls and .IgnorePublicAcls and .BlockPublicPolicy and .RestrictPublicBuckets')
    [ "$STATUS" != "true" ] && echo "PUBLIC: $bucket"
  done

# Check ALB listener rules for HTTP (non-HTTPS)
aws elbv2 describe-listeners \
  --query 'Listeners[?Protocol==`HTTP`].{ARN:ListenerArn,Port:Port,ALB:LoadBalancerArn}' \
  --output table
```

**Network checklist:**
- [ ] No SSH (22) or RDP (3389) open to 0.0.0.0/0
- [ ] No database ports (5432, 3306, 27017) open to 0.0.0.0/0
- [ ] RDS instances not publicly accessible
- [ ] S3 Block Public Access enabled
- [ ] HTTP redirects to HTTPS on all ALBs

---

## 8. Compliance Checks

```bash
# AWS Security Hub findings summary
aws securityhub get-findings \
  --filters '{"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"},{"Value":"HIGH","Comparison":"EQUALS"}]}' \
  --query 'Findings[*].{Title:Title,Severity:Severity.Label,Resource:Resources[0].Id}' \
  --output table | head -50

# CIS Benchmark compliance score
aws securityhub describe-standards-subscriptions
aws securityhub get-enabled-standards
```

---

## Audit Summary Report

After running all checks, generate summary:
```bash
echo "=== Security Audit Summary ==="
echo "Date: $(date -u)"
echo "Code: ${CODE_DIR}"
echo "Image: ${IMAGE}"
echo ""
echo "Secrets scan:     [ PASS / FAIL ]"
echo "SAST:             [ PASS / FAIL ] (N findings)"
echo "Dependencies:     [ PASS / FAIL ] (N HIGH, N CRITICAL)"
echo "IaC scan:         [ PASS / FAIL ] (N HIGH, N CRITICAL)"
echo "Image scan:       [ PASS / FAIL ] (N HIGH, N CRITICAL)"
echo "IAM review:       [ PASS / FAIL ]"
echo "Network review:   [ PASS / FAIL ]"
echo ""
echo "Overall: [ APPROVED / BLOCKED ]"
echo "Reviewer: ${REVIEWER}"
```

---
**Used by:** cicd-engineer (DevOps pack)
**Related playbooks:** terraform-plan-apply.md, k8s-deploy-safe.md
