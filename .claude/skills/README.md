# Skills – Claude Code

This directory contains **passive skills** used by Claude Code to specialize behavior depending on context.
Each skill includes a `CLAUDE.md` that augments the global rules with domain-specific guidance.

## Directory Structure

Skills are organized by category for easier navigation and management:

```
~/.claude/skills/
├── cloud-infrastructure/      ☁️  AWS, Kubernetes, Terraform, etc.
├── containers-docker/         🐳 Docker, Docker Compose, container security
├── application-development/   💻 Java, Node.js, and other languages
├── devops-cicd/              🔧 Git, GitHub Actions, CI/CD pipelines
└── operations-monitoring/     🔒 Security, observability, FinOps
```

## How Skills Work
- Global rules apply from the root `CLAUDE.md`
- When working inside a skill folder, Claude Code **inherits** that skill
- Project-level `CLAUDE.md` can further override behavior
- Skills can be combined mentally when needed (e.g., `aws + terraform + finops`)

## Skills Catalog

### ☁️ Cloud & Infrastructure (`cloud-infrastructure/`)

**`aws/`**
Use when working with AWS services, architecture, security, networking, and operations. Covers IAM/IRSA, EC2/ECS/EKS compute choices, S3 lifecycle, VPC design, RDS, Savings Plans, and CloudWatch.

**`terraform/`**
Use for Infrastructure as Code with Terraform: state management (S3+DynamoDB), modules, backends, OIDC for CI/CD, cost gating with Infracost, and security scanning with Checkov.

**`kubernetes/`**
Use for Kubernetes clusters, workloads, RBAC, networking, and operations. Covers pod specs with probes/limits, NetworkPolicy, HPA, PDB, Helm, and debugging commands.

**`istio/`**
Use when dealing with service mesh, traffic management, mTLS, and mesh observability. Covers VirtualService, DestinationRule, canary deployments, and circuit breaking.

**`argocd/`**
Use for GitOps workflows, Argo CD applications, sync strategies, and drift management. Covers App of Apps, AppProject RBAC, Notifications, and Image Updater.

**`database/`**
Use when working with RDS, Aurora, DynamoDB, or PostgreSQL. Covers engine selection, Multi-AZ vs Read Replicas, connection pooling, zero-downtime migrations, and backup/restore.

**`mysql/`**
Use when working with MySQL 8.x or MariaDB on RDS or self-managed. Covers utf8mb4, InnoDB, EXPLAIN output (type/key/Extra), composite index ordering, ALGORITHM=INSTANT/INPLACE DDL, pt-osc, gh-ost, GTID replication, ProxySQL, RDS Blue/Green Deployments, and Performance Schema queries. Agent: mysql-agent.

---

### 🐳 Containers & Docker (`containers-docker/`)

**`docker/`**
Use for Docker and Docker Compose: Dockerfiles, multi-stage builds, image optimization, networking, volumes, and production best practices.

**`docker-ci/`**
Use for Docker in CI/CD pipelines: build caching, registry management, security scanning, and automated builds.

**`docker-security/`**
Use for container security: image hardening, vulnerability scanning, runtime security, and secure configurations.

---

### 💻 Application Development (`application-development/`)

**`java/`**
Use for Java/Spring Boot development, REST APIs, JPA, security, testing, and enterprise-grade practices.

**`nodejs/`**
Use for Node.js/Express backend development, TypeScript, observability/APM with pino and prom-client, security, testing, and production best practices.

**`python/`**
Use for Python development: PEP 8, Black/Ruff formatting, type hints, Poetry/pip-tools dependency management, FastAPI, pytest, async patterns, and structlog. Agent: personal-engineering-agent.

**`frontend/`**
Use for React and Next.js development: TypeScript strict mode, Server vs Client Components, TanStack Query, Vitest/RTL testing, bundle optimization, and SSR/SSG/ISR rendering strategies. Agent: personal-engineering-agent.

**`api-design/`**
Use when designing or reviewing HTTP APIs: REST resource naming, status codes, RFC 7807 error format, pagination, versioning, idempotency keys, and OpenAPI specs.

---

### 🔧 DevOps & CI/CD (`devops-cicd/`)

**`git/`**
Use for Git workflows, trunk-based development, Conventional Commits, history safety, branching, and collaboration.

**`github-actions/`**
Use for GitHub Actions CI/CD pipelines: SHA-pinned actions, OIDC for AWS, caching, matrix builds, security scanning with Trivy, reusable workflows (`workflow_call`), and composite actions. Agent: ci-agent.

**`ci-cd/`**
Use for higher-level pipeline architecture: build-once-promote pattern, quality gates, blue-green and canary deployments, rollback triggers, and artifact management.

**`release-management/`**
Use for release process: semantic versioning, Conventional Commits → CHANGELOG automation, GitHub Releases, release branches, hotfix workflow, and semantic-release / release-please tooling. Agent: ci-agent.

**`workflows/`**
Reusable procedure library: feature development, bug fix, code review, dependency updates, database migrations, performance investigation, security incident, feature flags, and canary deployments.

---

### 🔒 Operations & Monitoring (`operations-monitoring/`)

**`security/`**
Use when security considerations are primary: OWASP Top 10, IAM least privilege, secrets management hierarchy, container security, and CI/CD security gates. Agent: security-agent.

**`secrets-management/`**
Use for all secret lifecycle concerns: AWS Secrets Manager, SSM Parameter Store, Vault basics, secret injection in ECS/K8s, automated rotation (dual-credential pattern), and pipeline secret scanning. Agent: security-agent. Playbook: secret-rotation.md.

**`observability/`**
Use for logs, metrics, traces, alerting, and SLO/SLA discussions. Covers Prometheus, PromQL, Grafana, OpenTelemetry, SLOTH SLO templates, trace-log correlation, pino structured logging, and error budget burn rate alerts. Agent: observability-agent.

**`networking/`**
Use for VPC design, routing, DNS, load balancing, and traffic analysis. Covers 3-tier VPC, SG vs NACL, NAT Gateway costs, VPC Endpoints, Route53, and K8s networking troubleshooting.

**`incidents/`**
Use during outages, troubleshooting, incident response, and postmortems. Covers SEV1-4 matrix, 15-minute golden window, signal gathering commands, and blameless RCA templates. Agent: incident-agent.

**`finops/`**
Use for cost analysis, optimization, budgets, and cloud financial governance. Covers EC2/RDS rightsizing, NAT Gateway optimization, Savings Plans, S3 storage classes, and waste audits. Agent: finops-agent.

**`monitoring-as-code/`**
Use when creating Prometheus alerting rules, recording rules, Alertmanager config, Grafana dashboards as code, SLO-based alerts, and promtool unit tests. Agent: observability-agent.

## Best Practices
- Combine skills mentally when needed (e.g., `aws + terraform + finops`)
- Prefer skills over ad-hoc instructions; skills provide domain-specific judgment
- Use `skill validate <name>` to check a skill has all required sections
- Use `skill new <category/name>` to create a new skill from template
- Evolve skills as your practices mature
