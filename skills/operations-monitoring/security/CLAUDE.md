# Skill: Security

## Scope

Aplicação de práticas de segurança em aplicações, infraestrutura, pipelines CI/CD e operações cloud. Cobre OWASP Top 10, IAM, gestão de segredos, criptografia, segurança de supply chain, scanning de vulnerabilidades e resposta a incidentes de segurança.

## Core Principles

- **Least privilege everywhere** — IAM roles, container users, database permissions, network access
- **Defense in depth** — múltiplas camadas de controles; nenhuma camada é suficiente sozinha
- **Shift left** — segurança integrada no desenvolvimento, não auditada depois
- **Fail secure** — em caso de falha, negar acesso (fail closed, não fail open)
- **Zero trust** — nunca assuma confiança implícita por localização de rede ou serviço interno
- **Audit everything** — logs de acesso, mudanças de configuração, ações administrativas

## Application Security (OWASP Top 10)

**A01 - Broken Access Control:**
- Enforce authorization server-side, não apenas no frontend
- Validate object ownership on every request (IDOR prevention)
- Use deny-by-default for resource access

**A02 - Cryptographic Failures:**
- Use TLS 1.2+ everywhere; enforce HSTS
- Never store passwords in plaintext; use bcrypt/Argon2 (cost factor >= 12)
- Encrypt sensitive data at rest (AES-256-GCM)
- Never roll your own crypto

**A03 - Injection:**
- Parameterized queries / ORMs — never string concatenation for SQL
- Validate and sanitize all user inputs
- Content-Security-Policy headers to prevent XSS

**A05 - Security Misconfiguration:**
- Disable debug endpoints in production
- Remove default credentials
- Enforce security headers (CSP, X-Frame-Options, X-Content-Type-Options)

**A06 - Vulnerable Components:**
- Run `npm audit`, `pip audit`, `trivy fs` regularly
- Pin dependency versions; review updates before merging
- Use Dependabot or Renovate for automated PRs

**A07 - Auth Failures:**
- Implement rate limiting on auth endpoints
- Use short-lived tokens (JWT exp <= 1h, refresh tokens with rotation)
- Log failed auth attempts; alert on anomalies

## Infrastructure Security

**AWS Security Baseline:**
- Enable AWS Config, GuardDuty, SecurityHub, CloudTrail in all accounts
- Block public access on all S3 buckets by default
- Enforce MFA on root account and IAM users
- Use Service Control Policies (SCPs) to enforce guardrails at org level
- Enable VPC Flow Logs
- Use AWS Config rules for compliance drift detection

**Network Security:**
- Security groups: principle of least privilege (specific ports, source CIDRs)
- No 0.0.0.0/0 on inbound except ALBs/NLBs facing internet
- Separate subnets for public/private/database tiers
- NACLs as secondary defense layer
- VPC endpoints to avoid traffic through internet for AWS APIs

## IAM & Identity

**IAM Best Practices:**
```json
// Prefer roles over users
// Never use root account for operations
// MFA on all human users
// Use aws:RequestedRegion conditions to limit region scope

// Example: Deny actions outside allowed regions
{
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:RequestedRegion": ["us-east-1", "us-west-2"]
    }
  }
}
```

**Role Design:**
- One role per workload/service (not shared)
- Use `aws:PrincipalTag` conditions for attribute-based access
- Avoid `*` in Action or Resource; use specific ARNs
- Use permission boundaries for delegated administration
- Review and rotate access keys; prefer OIDC/role assumption

## Secrets Management

**Hierarchy (prefer in order):**
1. AWS IAM roles (no credentials at all — best)
2. AWS Secrets Manager (rotation, audit, cross-account)
3. AWS SSM Parameter Store (SecureString — cheaper)
4. HashiCorp Vault (multi-cloud, dynamic secrets)
5. Kubernetes Secrets (base64, not encrypted by default — use External Secrets Operator)

**Never:**
- Hardcode credentials in code or Dockerfiles
- Store secrets in environment variables in plain Dockerfile
- Commit `.env` files with real values
- Log secrets (mask in log output)

**Rotation:**
- Enable automatic rotation in Secrets Manager (Lambda rotation function)
- Use dynamic credentials where possible (Vault database secrets engine)
- Audit secret access in CloudTrail

## Cryptography & TLS

- Use ACM (AWS Certificate Manager) for managed cert renewal
- Enforce TLS 1.2+ minimum; disable TLS 1.0/1.1
- Use ECDSA certificates where possible (smaller, faster)
- HSTS with `max-age=31536000; includeSubDomains; preload`
- Use encryption contexts with KMS for audit trail
- Rotate encryption keys annually (or per policy)

## Supply Chain Security

- Pin base images to digest: `FROM node:20-alpine@sha256:...`
- Scan images with Trivy, Grype, or Snyk before push
- Sign images with cosign (Sigstore)
- Use SBOM (Software Bill of Materials) generation: `syft image`
- Verify signatures on deployment: `cosign verify`
- Use private registries; don't pull untrusted images at runtime

## Container Security

- Run as non-root: `USER 1000:1000` in Dockerfile
- Read-only root filesystem: `readOnlyRootFilesystem: true` in K8s
- Drop all capabilities: `capabilities.drop: [ALL]`, add only what's needed
- No privileged containers
- No host network/PID namespace
- Seccomp profiles (RuntimeDefault minimum)
- Use distroless or scratch base images for production

## Security in CI/CD

**Pipeline Security Gates:**
```yaml
# Required checks before merge/deploy:
- secret-scan: detect-secrets, trufflehog, gitleaks
- sast: semgrep, sonarqube
- dependency-scan: npm audit --audit-level=high
- iac-scan: checkov, tfsec, terrascan
- container-scan: trivy image --exit-code 1 --severity HIGH,CRITICAL
```

**Branch Protection:**
- Require signed commits
- Require status checks before merge
- No force pushes to main/master
- Require code review from CODEOWNERS

## Vulnerability Management

- Triage by CVSS score + exploitability (EPSS score)
- Critical/High: fix within 24h (production) / 7 days (non-prod)
- Medium: fix within 30 days
- Accept/defer with documented justification
- Track in security backlog, not just issue tracker

## Compliance & Audit

- Enable CloudTrail in all regions with log file integrity validation
- S3 access logging on sensitive buckets
- Use AWS Config for configuration compliance
- IAM Access Analyzer for unused permissions
- Regular penetration testing (document scope and authorization)

## Common Mistakes / Anti-Patterns

- Wildcard `*` in IAM policies "because it's easier"
- Storing secrets in environment variables passed through CI/CD logs
- Using the same IAM role for multiple services (blast radius)
- Not validating JWT signatures server-side
- Over-privileged service accounts (cluster-admin for everything)
- Ignoring CVEs because "we don't expose that endpoint"
- HTTP in internal services "because it's internal"
- Not rotating credentials after engineer offboarding

## Communication Style

When this skill is active:
- Proactively flag security risks before implementing
- Explain the threat model, not just the fix
- Prefer showing secure alternatives over just listing problems
- Indicate severity (Critical/High/Medium/Low) clearly
- Reference OWASP, CVE, or CIS benchmarks when applicable

## Expected Output Quality

- Specific, actionable security controls — not vague advice like "use HTTPS"
- Include concrete examples (IAM policies, Kubernetes manifests, code snippets)
- Highlight trade-offs between security and usability/cost
- Always explain the attack vector being mitigated

---
**Skill type:** Passive
**Applies with:** aws, kubernetes, docker-security, terraform, ci-cd
**Pairs well with:** aws-platform-agent, personal-engineering-agent
