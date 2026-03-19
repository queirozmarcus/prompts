# AI Operating System for Backend, Microservices, DevOps, Kubernetes and Terraform
## Reverse-engineered and expanded from `claude-home-v6.zip`

> **Built directly from the ZIP you sent.**
>
> This manual does not treat the material as a generic inspiration. It preserves the original ecosystem structure found in the archive and evolves it into a denser, more operational, backend/DevOps-focused system.

---

## Executive summary

The ZIP contains a complete local AI operating environment organized around four layers:

1. **A global orchestrator** (`marcus-agent`) that classifies requests, scans the project, and routes execution.
2. **Specialist agents** grouped by domain: development, QA, DevOps/SRE, data, and monolith migration.
3. **Slash commands** that orchestrate multiple agents into repeatable workflows.
4. **Passive skills and playbooks** that inject domain best practices and reusable operational sequences.

### Inventory extracted from the ZIP

- **36 agents**
- **30 commands**
- **28 passive skills**
- **12 playbooks**
- Global files: `CLAUDE.md`, `README.md`, `MANUAL-CASOS-DE-USO.md`, `install.sh`

### What this evolved manual adds

Compared to the original material, this manual expands the system with:

- a stronger **backend + microservices + platform engineering** operating model
- **full + lite** versions for commands
- more explicit **inputs / outputs / artifacts**
- operational guidance for **Kubernetes, Terraform, CI/CD, observability, incidents, FinOps, GitOps, security**
- real-world playbooks for **CrashLoopBackOff, latency, rollout failure, drift, noisy neighbor, failed migrations**
- a **maturity model** from beginner to expert
- a section for **bad prompts vs. good prompts**
- an evolved command language ready for daily use

---

# PART 1 — System vision reconstructed from the ZIP

## 1.1 Original architecture discovered in the archive

The ZIP implements a **terminal-first AI engineering operating system** inspired by agent ecosystems such as Claude Code. The architecture is based on a simple but powerful pattern:

```text
User request
  -> Marcus (global router)
    -> direct specialist agent OR slash command OR playbook suggestion
      -> specialist agents execute in sequence
        -> passive skills enrich the execution context
          -> output = code, infra, tests, runbooks, reviews, plans
```

## 1.2 Core building blocks found in the ZIP

### A. Global orchestration
The orchestrator is `marcus-agent.md`. Its responsibilities in the ZIP are:

- scan the project at startup
- detect stack and infra signals (`pom.xml`, `Dockerfile`, Helm, Terraform, GitHub Actions, Flyway)
- classify the request
- recommend the best command or specialist path
- **never implement directly**
- act as an expert in the ecosystem itself: commands, plugins, packs, skills, playbooks

### B. Domain packs
The ZIP is effectively split into five operating packs:

| Pack | Goal | Typical output |
|---|---|---|
| Dev | service design and implementation | API, use case, repository, config, review |
| QA | test generation and audit | unit/integration/contract/e2e/security/perf |
| DevOps | platform, infra, runtime | Terraform, Helm, CI/CD, observability, runbooks |
| Data | schema and performance | migrations, indexing, query tuning |
| Migration | monolith decomposition | discovery, seams, extraction, decommission |

### C. Commands as workflow interfaces
The commands in `/commands` are not mere shortcuts. They are **workflow entrypoints**. Each command defines:

- a problem framing
- the ordered sequence of specialists
- the expected output
- a handoff to the next workflow when needed

Example reconstructed from the ZIP:
- `/dev-feature` = architect → api-designer → dba → backend-dev → code-reviewer
- `/devops-provision` = iac-engineer → kubernetes-engineer → cicd-engineer → observability-engineer → security-ops
- `/full-bootstrap` = Dev pack → QA pack → DevOps pack

### D. Passive skills as invisible best-practice injectors
The `/skills` tree contains domain manuals that enrich sessions automatically. These cover:

- Java
- API design
- testing
- AWS
- database
- Istio
- Kubernetes
- Terraform
- Docker
- CI/CD
- GitHub Actions
- release management
- incidents
- observability
- networking
- security
- FinOps
- secrets management

This is an important architectural pattern from the ZIP: **agents do not need to restate all best practices every time because skills provide passive domain context**.

### E. Playbooks as reusable operational sequences
The `/playbooks` directory contains scenario-driven guidance, including:

- incident response
- safe K8s deploy
- rollback
- DR drill / restore
- terraform plan/apply
- network troubleshooting
- secret rotation
- database migration
- cost optimization
- dependency update
- security audit

This means the system has two operating modes:

1. **Command mode** for task execution.
2. **Playbook mode** for situation handling.

## 1.3 Structural pattern preserved from the ZIP

The archive follows this architectural contract:

```text
Marcus = gateway
Commands = orchestration interfaces
Agents = specialists
Skills = passive knowledge
Playbooks = battle-tested sequences
Checks = micro-checklists
```

That is the right architecture. It is worth preserving.

## 1.4 Main strengths of the original ZIP

- clear separation of concerns
- strong focus on Java/Spring backend and platform engineering
- production-minded defaults
- serious attention to observability, security, and operations
- migration support for monolith-to-microservices
- good use of commands as process abstraction
- practical Kubernetes and Terraform guidance
- incident/runbook orientation rather than purely academic descriptions

## 1.5 Main upgrade opportunities

This manual expands the ZIP in five key ways:

1. stronger unification of **backend + platform + runtime + cost**
2. richer **input/output contracts** for every command and agent
3. more explicit **day-2 operations**
4. **lite command mode** for fast daily execution
5. more coverage for **microservice reality**: rollouts, logs, queues, retries, idempotency, spot nodes, mesh, drift, noisy neighbors

---

# PART 2 — Expanded agent system

## 2.1 Original agent inventory found in the ZIP

### Global orchestrator
- `marcus-agent`

### Development and architecture
- `architect`
- `api-designer`
- `backend-dev`
- `backend-engineer`
- `code-reviewer`
- `refactoring-engineer`
- `tech-lead`
- `domain-analyst`

### QA and testing
- `qa-engineer`
- `qa-lead`
- `test-automation-engineer`
- `unit-test-engineer`
- `integration-test-engineer`
- `contract-test-engineer`
- `e2e-test-engineer`
- `security-test-engineer`
- `performance-engineer`

### DevOps / platform / SRE / cloud
- `devops-engineer`
- `devops-lead`
- `kubernetes-engineer`
- `iac-engineer`
- `cicd-engineer`
- `observability-engineer`
- `sre-engineer`
- `platform-engineer`
- `gitops-engineer`
- `service-mesh-engineer`
- `aws-cloud-engineer`
- `finops-engineer`
- `security-ops`
- `security-engineer`

### Data
- `database-engineer`
- `mysql-engineer`
- `dba`
- `data-engineer`

## 2.2 Evolved role model

The system becomes stronger if you classify agents by **operating responsibility**, not only by team:

| Operating layer | Agents | Mission |
|---|---|---|
| Routing | marcus-agent | classify, prioritize, route, choose workflow |
| Design | architect, api-designer, domain-analyst, tech-lead | service boundaries, contracts, ADRs |
| Build | backend-dev, backend-engineer, refactoring-engineer | code and service evolution |
| Verify | code-reviewer, qa-lead, test agents, security-test-engineer, performance-engineer | correctness, safety, quality gates |
| Run | devops-engineer, kubernetes-engineer, cicd-engineer, observability-engineer, sre-engineer, platform-engineer | deploy, operate, stabilize |
| Govern | security-ops, security-engineer, finops-engineer, gitops-engineer | policy, security, cost, change control |
| Data | dba, database-engineer, mysql-engineer, data-engineer | schema, performance, migration, data splitting |

## 2.3 Agent contracts

Below is the evolved operational contract for the most important agents.

### 2.3.1 `marcus-agent`
**Function**  
Global router. Reads context, chooses path, never codes directly.

**When to use**  
Always. It is the entrypoint for:
- “build something”
- “debug something”
- “what is the best command”
- “which agent should handle this”
- “I have a production issue”

**Input**  
A plain-language engineering request.

**Output**  
- recommended command or workflow
- delegated sequence
- brief rationale
- next command to run

**Real example**
```text
Input:
"Order service in EKS is returning 503 after today's deploy."

Output:
Best path: /devops-incident "order-service 503 after deploy"
Why: this is runtime failure, probably rollout, readiness, downstream, or mesh related.
Expected sequence: sre-engineer -> observability-engineer -> kubernetes-engineer
Immediate goal: stabilize first, explain later.
```

### 2.3.2 `architect`
**Function**  
Translates requirements into service shape, boundaries, decisions, adapters, and ADRs.

**When to use**
- new feature with architectural impact
- new service
- cross-service change
- migration planning
- technical debt prioritization

**Input**
- business requirement
- service context
- known constraints

**Output**
- design summary
- impacted modules
- decision log / ADR
- risks
- recommended implementation sequence

**Real example**
```text
Task:
"Add idempotent payment confirmation and prevent duplicate webhook processing."

Architect output:
- Add inbound webhook adapter
- Create idempotency key storage
- Use application use case ConfirmPaymentUseCase
- Store external_event_id unique index
- Add replay-safe status transition rules
- Add ADR: exactly-once is not guaranteed, therefore enforce at-least-once + idempotency
```

### 2.3.3 `backend-dev`
**Function**  
Implements backend code using the stack style found in the ZIP: Java/Spring, hexagonal, Flyway, OpenAPI, observability hooks.

**When to use**
- service scaffolding
- feature implementation
- integration with Kafka/Redis/DB
- Java version-aware implementation

**Input**
- architecture/design
- API contract
- data model
- coding conventions

**Output**
- packages
- controller/use case/repository/config
- migrations
- properties
- structured logging / actuator / health hooks

**Real example**
```text
Implements:
controller -> application use case -> domain rule -> persistence adapter
Adds:
- Problem Details error handling
- structured logs
- health/readiness endpoints
- graceful shutdown
- Flyway migration
```

### 2.3.4 `kubernetes-engineer`
**Function**  
Turns a service into a production-grade workload in K8s.

**When to use**
- first deploy to EKS
- crashloop, readiness, resource, scheduling, HPA issues
- Helm authoring
- PDB, probes, anti-affinity, spot strategy

**Input**
- workload type
- runtime profile
- SLO expectation
- environment constraints

**Output**
- Deployment/Service/HPA/PDB/ServiceAccount/NetworkPolicy/Ingress or Helm chart
- rollout strategy
- runtime risk notes

**Real example**
```yaml
Key outputs:
- startupProbe for slow Spring Boot startup
- readinessProbe that checks DB dependency only if required
- requests/limits based on profile
- topology spread constraints
- taints/tolerations for spot-compatible workers
```

### 2.3.5 `iac-engineer`
**Function**  
Builds and evolves Terraform infrastructure safely.

**When to use**
- new environment components
- IAM / network / database / cache / messaging infra
- terraform drift remediation
- module design

**Input**
- target cloud
- environment
- component needs
- state/backend conventions

**Output**
- Terraform files or module changes
- variables / outputs
- validation path
- plan/apply sequencing
- drift / blast-radius analysis

### 2.3.6 `observability-engineer`
**Function**  
Defines what must be measurable before the service reaches production.

**When to use**
- new service bootstrap
- missing dashboards
- latency investigation
- SLO/alert tuning

**Input**
- service purpose
- critical user flows
- infra/runtime topology

**Output**
- metrics and labels
- dashboard design
- alert rules
- trace/log correlation fields
- RED/USE coverage

### 2.3.7 `sre-engineer`
**Function**  
Incident commander and runtime stabilizer.

**When to use**
- degraded production
- elevated error rate
- rollout gone wrong
- dependency meltdown

**Input**
- symptom
- timeline
- blast radius
- current metrics/logs/events

**Output**
- stabilization plan
- immediate mitigations
- diagnosis hypothesis tree
- rollback/scale/rate-limit actions
- postmortem structure

### 2.3.8 `security-ops`
**Function**  
Applies runtime and delivery security.

**When to use**
- RBAC, secrets, image scanning, network policy, hardening
- release readiness review
- cloud posture review

**Output**
- least-privilege recommendations
- security controls
- CI/CD gates
- cluster/network protections

### 2.3.9 `finops-engineer`
**Function**  
Cost-aware architecture and runtime efficiency.

**When to use**
- cost spikes
- service right-sizing
- spot adoption
- infra design trade-offs

**Output**
- cost drivers
- efficiency actions
- savings estimate
- operational caveats

## 2.4 New agents recommended on top of the ZIP

These do not exist explicitly in the archive, but they are natural upgrades:

| New agent | Why it should exist |
|---|---|
| `log-forensics-engineer` | deep correlation of application logs, ingress logs, ALB logs, and trace IDs |
| `workload-rightsizer` | dedicated requests/limits/HPA/VPA/spot sizing |
| `event-driven-architect` | Kafka, outbox, retries, DLQ, idempotency, ordering |
| `release-governor` | progressive delivery, freeze windows, canary policies, rollback quality |
| `platform-product-manager` | translates platform capabilities into service templates and paved roads |

---

# PART 3 — Commands: preserved and evolved

## 3.1 Original commands found in the ZIP

- `/data-migrate`
- `/data-optimize`
- `/dev-api`
- `/dev-bootstrap`
- `/dev-feature`
- `/dev-refactor`
- `/dev-review`
- `/devops-audit`
- `/devops-cloud`
- `/devops-dr`
- `/devops-finops`
- `/devops-gitops`
- `/devops-incident`
- `/devops-mesh`
- `/devops-observe`
- `/devops-pipeline`
- `/devops-provision`
- `/full-bootstrap`
- `/migration-decommission`
- `/migration-discovery`
- `/migration-extract`
- `/migration-prepare`
- `/qa-audit`
- `/qa-contract`
- `/qa-e2e`
- `/qa-flaky`
- `/qa-generate`
- `/qa-performance`
- `/qa-review`
- `/qa-security`

## 3.2 Command operating contract

Every command should follow this format:

```text
Purpose
When to run
Inputs required
Agents involved
Execution steps
Artifacts generated
Risks / caveats
Next commands
Lite version
```

## 3.3 Evolved command catalog

Below are the most useful commands, preserving the ZIP foundation and extending it.

### `/design-service`
**Status**: new command added by this manual  
**Purpose**: design a new microservice before coding.

**Agents involved**
- architect
- domain-analyst
- api-designer
- dba
- observability-engineer
- security-ops

**Full prompt**
```text
/design-service "Create notification-service for email + SMS + push with retry policy, idempotency, delivery status tracking, OpenAPI, Kafka integration, Prometheus metrics, Helm deployment, and Terraform dependencies."
```

**Expected output**
- service responsibility statement
- bounded context
- inbound/outbound dependencies
- API contract
- event contract
- persistence model
- observability baseline
- security baseline
- ADR draft

**Lite**
```text
/design-service-lite "notification-service for delivery orchestration"
```

---

### `/dev-feature`
**Status**: preserved from ZIP  
**Purpose**: implement a feature end-to-end.

**Agents involved**
- architect
- api-designer
- dba
- backend-dev
- code-reviewer

**Full prompt**
```text
/dev-feature "Add cursor-based search for orders with filters status, tenant_id, created_at range, response pagination metadata, and index strategy for PostgreSQL."
```

**Real output artifacts**
- endpoint contract
- request/response DTOs
- use case
- repository query
- Flyway migration
- review notes
- next step: `/qa-generate SearchOrdersUseCase`

**Lite**
```text
/dev-feature-lite "search orders by status and date"
```

---

### `/k8s-debug`
**Status**: new command added by this manual  
**Purpose**: debug an unhealthy Kubernetes workload quickly.

**Agents involved**
- sre-engineer
- kubernetes-engineer
- observability-engineer
- log-forensics-engineer

**Full prompt**
```text
/k8s-debug "payments-api in namespace prod is CrashLoopBackOff after rollout 2026.03.18-3; investigate probes, OOM, config, secret mounts, recent image, events, and propose stabilization."
```

**Expected steps**
1. collect pod status, events, restart reason
2. inspect current and previous container logs
3. compare rollout revision
4. check probes, env, configmap/secret, image tag, resources
5. stabilize with rollback/scale/fix path

**Lite**
```text
/k8s-debug-lite "payments-api crashloop in prod"
```

---

### `/terraform-apply`
**Status**: new operational wrapper  
**Purpose**: run safe Terraform change control.

**Agents involved**
- iac-engineer
- security-ops
- finops-engineer
- devops-lead

**Full prompt**
```text
/terraform-apply "Apply Redis cluster and IAM policy changes in prod; require fmt, validate, security scan, cost note, blast radius summary, targeted rollback notes, and safe apply sequence."
```

**Expected output**
- preflight checklist
- plan interpretation
- risk summary
- cost impact
- apply sequencing
- rollback notes

**Lite**
```text
/terraform-apply-lite "review and apply redis change"
```

---

### `/analyze-logs`
**Status**: new command added by this manual  
**Purpose**: convert raw logs into hypotheses and next actions.

**Agents involved**
- log-forensics-engineer
- observability-engineer
- sre-engineer
- backend-dev

**Full prompt**
```text
/analyze-logs "Correlate application JSON logs, ingress logs, and trace ids for 502/503 spikes between 10:30 and 11:10; identify dominant failure mode and whether issue is app startup, dependency timeout, auth failure, or mesh."
```

**Lite**
```text
/analyze-logs-lite "why did 503 spike after deploy"
```

---

### `/devops-provision`
**Status**: preserved from ZIP  
**Purpose**: infra bootstrap for a service.

**Agents involved**
- iac-engineer
- kubernetes-engineer
- cicd-engineer
- observability-engineer
- security-ops
- devops-lead

**Full prompt**
```text
/devops-provision order-service aws
```

**Lite**
```text
/devops-provision-lite "order-service aws"
```

---

### `/devops-incident`
**Status**: preserved from ZIP  
**Purpose**: production incident handling.

**Agents involved**
- sre-engineer
- observability-engineer
- kubernetes-engineer
- security-ops when relevant

**Full prompt**
```text
/devops-incident "checkout-service p99 at 4.8s and 12% 5xx in prod after dependency timeout spikes; determine blast radius, stabilize traffic, and produce status update."
```

**Lite**
```text
/devops-incident-lite "checkout high latency and errors"
```

---

### `/qa-security`
**Status**: preserved from ZIP  
**Purpose**: automate security testing of an endpoint or service.

**Lite**
```text
/qa-security-lite "order-service"
```

---

### `/migration-extract`
**Status**: preserved from ZIP  
**Purpose**: extract a bounded context from the monolith.

**Lite**
```text
/migration-extract-lite "payment"
```

## 3.4 Recommended new command family

| New command | Use |
|---|---|
| `/design-service` | service design before code |
| `/k8s-debug` | pod / deploy / probe / scheduling debug |
| `/terraform-apply` | safer change control for Terraform |
| `/analyze-logs` | log-to-hypothesis workflow |
| `/release-check` | release readiness before prod |
| `/spot-readiness` | verify if a workload can safely run on spot |
| `/event-contract` | design Kafka events, outbox, retries, DLQ |
| `/rightsizing` | requests/limits/HPA tuning |
| `/drift-audit` | Terraform and cluster drift investigation |
| `/slo-bootstrap` | create first SLOs and alerts for a service |

---

# PART 4 — Lite versions for all command families

## 4.1 Why lite mode is necessary

The ZIP is strong for deep workflows, but daily engineering often needs a faster interface. Lite mode should:

- compress the prompt
- reduce ceremony
- bias toward first useful output
- still preserve the same routing logic

## 4.2 Lite prompt pattern

```text
/<command>-lite "<service or problem>"
```

The contract is:

- assume default stack from the project
- skip long explanations
- produce top 3 actions
- include “what I need from you” only if truly blocking

## 4.3 Examples

| Full | Lite |
|---|---|
| `/dev-feature "Add tenant-aware cursor pagination for orders with Problem Details and index strategy"` | `/dev-feature-lite "tenant order search"` |
| `/k8s-debug "payments-api in prod CrashLoopBackOff after rollout, inspect probes/resources/secrets/events/logs"` | `/k8s-debug-lite "payments-api crashloop prod"` |
| `/terraform-apply "Review and apply IAM + Redis infra in prod with blast radius and cost notes"` | `/terraform-apply-lite "prod redis + iam change"` |
| `/analyze-logs "Correlate app/ingress/trace logs for 503 spike"` | `/analyze-logs-lite "503 spike cause"` |

## 4.4 Operational rule

Use **full** mode when:
- production risk is high
- architecture changes
- migration steps are involved
- security/compliance is material

Use **lite** mode when:
- you need fast triage
- you are iterating
- you are still shaping the problem
- the change is localized

---

# PART 5 — Real workflows based on the system

## 5.1 Workflow: create a new microservice

```text
/design-service
/dev-bootstrap
/qa-generate
/devops-provision
/slo-bootstrap
/release-check
```

### Agent sequence
architect → api-designer → dba → backend-dev → qa agents → iac-engineer → kubernetes-engineer → cicd-engineer → observability-engineer → security-ops

### Example
```text
Service: notification-service
Responsibilities:
- receive internal commands to notify users
- publish delivery status events
- integrate email provider and SMS provider
- expose idempotent delivery query endpoint
```

### Expected final artifacts
- OpenAPI spec
- service skeleton
- Flyway migrations
- Dockerfile
- Helm chart
- Terraform modules or environment wiring
- CI/CD workflow
- dashboard and SLO alerts
- runbook

## 5.2 Workflow: safe deploy to Kubernetes

```text
/release-check
/devops-pipeline
/devops-observe
/k8s-debug   # only if rollout signals degrade
```

### Deployment gate
- image built and scanned
- tests green
- probes validated
- startup time known
- requests/limits realistic
- rollback command ready
- alerts muted only if justified

### Real scenario
A Spring Boot service starts slowly after adding Flyway migrations.  
Fix path:
- add `startupProbe`
- relax initial readiness window
- pre-run migration job if needed
- avoid false-negative restarts during warm-up

## 5.3 Workflow: production failure after deploy

```text
/devops-incident
/analyze-logs
/k8s-debug
/rollback-strategy playbook
```

### Typical sequence
1. stabilize
2. rollback if needed
3. confirm symptom reduction
4. compare revisions
5. produce incident update
6. schedule follow-up fix

## 5.4 Workflow: build CI/CD for a new service

```text
/devops-pipeline
/qa-audit
/qa-security
/release-check
```

### Minimum pipeline stages
- build
- unit tests
- integration tests
- SAST / dependency scan
- image build
- image scan
- publish
- deploy to staging
- smoke test
- promotion gate
- production deploy
- post-deploy verification

## 5.5 Workflow: provision infra with Terraform

```text
/devops-cloud
/devops-provision
/terraform-apply
/drift-audit
```

### Example
Provision:
- RDS
- ElastiCache / Redis
- IAM roles
- S3 bucket
- secrets integration
- EKS namespace/service account wiring

---

# PART 6 — Massive use cases beyond the original material

## 6.1 APIs and backend runtime
- new CRUD service with pagination and filters
- idempotent webhook consumer
- outbox pattern with Kafka
- Redis cache with invalidation
- tenant isolation
- Problem Details standardization
- structured logging + trace correlation
- retry/backoff for downstream dependencies
- circuit breaker + timeout model
- Java 8 legacy compatibility path
- Java 21+ modernization path

## 6.2 Kubernetes and pods
- CrashLoopBackOff
- OOMKilled
- CPU throttling
- readiness probe flap
- node pressure eviction
- image pull backoff
- configmap/secret mismatch
- spot interruption handling
- HPA oscillation
- service mesh sidecar overhead
- anti-affinity causing unschedulable pods

## 6.3 Observability
- RED dashboards
- USE method for nodes and workloads
- SLO error-budget tracking
- high-cardinality metric cleanup
- trace propagation audit
- log schema standardization
- alert tuning to reduce noise

## 6.4 Terraform and infra
- infra drift
- unsafe state changes
- IAM blast radius
- NAT Gateway cost explosion
- VPC endpoint trade-offs
- DB sizing errors
- module sprawl
- environment parity problems
- plan review before apply

## 6.5 FinOps
- service right-sizing
- spot adoption analysis
- overprovisioned requests in K8s
- data transfer surprises
- underused databases
- waste from duplicated observability pipelines

## 6.6 Migration
- bounded context discovery
- seam creation
- shared-table split
- foreign key decoupling
- strangler pattern rollout
- functional parity validation
- decommission checklist

---

# PART 7 — Operational playbooks

## 7.1 Production is down
**Use**
```text
/devops-incident "service unavailable"
```

**Immediate order**
1. confirm blast radius
2. check recent deploy
3. rollback if correlated
4. verify pods / targets / dependency health
5. publish status update

## 7.2 Pod in CrashLoopBackOff
**Use**
```text
/k8s-debug "service crashloop"
```

**Check**
- previous logs
- entrypoint/config
- secret mount
- JVM options
- startup probe
- OOMKilled signal
- incompatible image tag

## 7.3 High latency
**Use**
```text
/devops-incident "p99 high latency"
/analyze-logs "slow requests"
```

**Check**
- DB connections
- slow query plan
- downstream timeout
- CPU throttle
- mesh retries amplifying latency
- ALB / ingress saturation

## 7.4 Deploy failed
**Use**
```text
/release-check
/k8s-debug
```

**Check**
- image digest mismatch
- wrong env vars
- migration blocking startup
- missing secret/configmap
- wrong readiness path
- rollout strategy too aggressive

## 7.5 Terraform drift
**Use**
```text
/drift-audit "prod networking"
/terraform-apply "reconcile safely"
```

**Check**
- manual console changes
- policy drift
- imported resources
- state mismatch
- unsafe destroy/create actions

## 7.6 Secret rotation
Use the original secret rotation playbook from the ZIP plus:
- dual-secret overlap window
- rotation rollback plan
- consumer refresh validation
- post-rotation smoke test

---

# PART 8 — Maturity model

## Level 1 — Beginner
**Behavior**
- asks for direct code or direct fixes
- uses one agent at a time
- reacts to problems only after they happen

**Goal**
Learn that commands are workflows, not shortcuts.

**Recommended commands**
- `/dev-feature-lite`
- `/qa-generate-lite`
- `/k8s-debug-lite`

## Level 2 — Practitioner
**Behavior**
- starts using the right specialist
- understands code + tests + deploy as one chain
- begins asking for safe rollout and observability

**Recommended commands**
- `/dev-feature`
- `/devops-provision`
- `/qa-audit`
- `/devops-observe`

## Level 3 — Advanced
**Behavior**
- thinks in service boundaries, contracts, SLOs, and blast radius
- uses commands in sequence
- anticipates operational concerns before deploy

**Recommended workflows**
- `/design-service -> /dev-bootstrap -> /qa-generate -> /devops-provision`
- `/release-check -> /devops-pipeline -> /devops-observe`

## Level 4 — Expert
**Behavior**
- designs paved roads
- optimizes for operability, cost, and recovery
- uses AI as a system of specialists, not as a generic assistant
- thinks in policies, templates, and reusable runbooks

**Expert habits**
- every service has a runbook
- every deploy has a rollback path
- every endpoint has timeout/retry/idempotency thinking
- every Terraform change has blast-radius review
- every K8s workload has requests/limits/probes tuned with evidence

---

# PART 9 — Real errors and corrections

## 9.1 Bad prompt vs optimized prompt

### Example A — vague implementation request
**Bad**
```text
Create an API for orders.
```

**Better**
```text
/dev-feature "Add REST API to search orders by tenant_id, status, and created_at range with cursor pagination, Problem Details errors, PostgreSQL index strategy, and OpenAPI documentation."
```

Why better:
- defines behavior
- defines constraints
- defines storage concern
- defines API standard
- reduces ambiguity

### Example B — vague K8s debug
**Bad**
```text
My pod is broken.
```

**Better**
```text
/k8s-debug "billing-api in prod is CrashLoopBackOff after image 2026.03.18.2; inspect events, previous logs, probes, JVM memory flags, mounted secrets, and recommend stabilization."
```

### Example C — vague Terraform request
**Bad**
```text
Apply Terraform.
```

**Better**
```text
/terraform-apply "Review and apply prod Redis + IAM changes with fmt/validate/security scan, blast radius summary, cost note, and rollback caveats."
```

## 9.2 Common DevOps/K8s anti-patterns

| Anti-pattern | Why it is bad | Correction |
|---|---|---|
| `latest` image tag | non-repeatable rollout | immutable tags / digests |
| no resource limits | noisy neighbor / instability | requests and limits based on profiling |
| readiness = liveness | false restarts | separate startup, liveness, readiness |
| manual prod kubectl edits | drift and hidden state | GitOps / manifests in Git |
| Terraform apply without reading plan | hidden blast radius | mandatory plan review |
| no rollback notes | slow incident recovery | write rollback path before deploy |
| no structured logs | weak triage | JSON logs + trace/request ids |
| no idempotency in async flows | duplicate side effects | dedupe keys + status transitions |
| no SLOs | unclear failure threshold | define latency and availability objectives |
| retry everywhere | retry storm | bounded retry + timeout + circuit break |

## 9.3 Common backend anti-patterns

| Anti-pattern | Fix |
|---|---|
| controller with business logic | move to use case / domain |
| repository returning entity graph blindly | query for use case |
| no DB index for primary filter | create index with migration |
| migration that rewrites live column destructively | zero-downtime migration pattern |
| logging without correlation id | add request/trace context |
| catching Exception generically | domain-specific exceptions + Problem Details |

---

# PART 10 — Advanced hacks

## 10.1 Think in layers, not prompts
Do not ask AI only for “the answer”. Ask it to operate the stack in layers:

1. **design**
2. **implement**
3. **verify**
4. **deploy**
5. **observe**
6. **stabilize**
7. **optimize**

That is exactly the strength of the ZIP architecture.

## 10.2 Use agent composition deliberately
Strong composition examples:

- **new service** = architect + backend-dev + dba + qa-lead + kubernetes-engineer + observability-engineer
- **incident** = sre-engineer + observability-engineer + kubernetes-engineer + log-forensics-engineer
- **cloud cost review** = aws-cloud-engineer + finops-engineer + devops-lead
- **migration** = domain-analyst + backend-engineer + data-engineer + qa-engineer + platform-engineer

## 10.3 Default prompt template for complex engineering work

```text
Context:
- service:
- environment:
- stack:
- recent changes:
- symptoms:
- constraints:

Goal:
- desired business/technical outcome

Need from the system:
- best command or workflow
- agents involved
- first safe action
- expected artifacts
- risks and rollback notes
```

## 10.4 Use “stabilize first, explain later”
In incidents, never ask for a long analysis first. Use the system to:

1. stop the bleeding
2. reduce impact
3. confirm stabilization
4. then investigate deeply

## 10.5 Use paved-road outputs
The best use of this system is not one-off answers. It is reusable outputs:

- templates
- Helm starters
- Terraform module patterns
- SLO packs
- service skeletons
- runbooks
- release checklists

That is how the ecosystem becomes a true personal operating system.

---

# PART 11 — Recommended daily operating model

## Morning
```text
1. ask Marcus for project scan
2. review open deploy/runtime risks
3. choose one workflow:
   - feature
   - infra
   - incident
   - migration
```

## During implementation
```text
- design first
- implement with agent specialization
- generate tests
- run review
- verify observability before merge
```

## Before deploy
```text
- release-check
- security review
- rollback plan
- post-deploy metrics to watch
```

## After deploy
```text
- watch p95/p99, 5xx, saturation, restart count
- confirm health and target readiness
- close the change only after runtime confirmation
```

---

# PART 12 — Appendices

## 12.1 Full agent inventory from the ZIP
- `api-designer`
- `architect`
- `aws-cloud-engineer`
- `backend-dev`
- `backend-engineer`
- `cicd-engineer`
- `code-reviewer`
- `contract-test-engineer`
- `data-engineer`
- `database-engineer`
- `dba`
- `devops-engineer`
- `devops-lead`
- `domain-analyst`
- `e2e-test-engineer`
- `finops-engineer`
- `gitops-engineer`
- `iac-engineer`
- `integration-test-engineer`
- `kubernetes-engineer`
- `marcus-agent`
- `mysql-engineer`
- `observability-engineer`
- `performance-engineer`
- `platform-engineer`
- `qa-engineer`
- `qa-lead`
- `refactoring-engineer`
- `security-engineer`
- `security-ops`
- `security-test-engineer`
- `service-mesh-engineer`
- `sre-engineer`
- `tech-lead`
- `test-automation-engineer`
- `unit-test-engineer`

## 12.2 Full command inventory from the ZIP
- `/data-migrate`
- `/data-optimize`
- `/dev-api`
- `/dev-bootstrap`
- `/dev-feature`
- `/dev-refactor`
- `/dev-review`
- `/devops-audit`
- `/devops-cloud`
- `/devops-dr`
- `/devops-finops`
- `/devops-gitops`
- `/devops-incident`
- `/devops-mesh`
- `/devops-observe`
- `/devops-pipeline`
- `/devops-provision`
- `/full-bootstrap`
- `/migration-decommission`
- `/migration-discovery`
- `/migration-extract`
- `/migration-prepare`
- `/qa-audit`
- `/qa-contract`
- `/qa-e2e`
- `/qa-flaky`
- `/qa-generate`
- `/qa-performance`
- `/qa-review`
- `/qa-security`

## 12.3 Full playbook inventory from the ZIP
- `cost-optimizat`
- `database-migrat`
- `dependency-upd`
- `dr-dr`
- `dr-rest`
- `incident-respo`
- `k8s-deploy-s`
- `network-troubleshoot`
- `rollback-strat`
- `secret-rotat`
- `security-au`
- `terraform-plan-ap`

## 12.4 Full passive skill inventory from the ZIP
- `application-development/api-design`
- `application-development/frontend`
- `application-development/java`
- `application-development/nodejs`
- `application-development/python`
- `application-development/testing`
- `cloud-infrastructure/argocd`
- `cloud-infrastructure/aws`
- `cloud-infrastructure/database`
- `cloud-infrastructure/istio`
- `cloud-infrastructure/kubernetes`
- `cloud-infrastructure/mysql`
- `cloud-infrastructure/terraform`
- `containers-docker/docker`
- `containers-docker/docker-ci`
- `containers-docker/docker-security`
- `devops-cicd/ci-cd`
- `devops-cicd/git`
- `devops-cicd/github-actions`
- `devops-cicd/release-management`
- `devops-cicd/workflows`
- `operations-monitoring/finops`
- `operations-monitoring/incidents`
- `operations-monitoring/monitoring-as-code`
- `operations-monitoring/networking`
- `operations-monitoring/observability`
- `operations-monitoring/secrets-management`
- `operations-monitoring/security`

## 12.5 Final recommendation

The ZIP already contains a very solid foundation. Its strongest architectural choice is the separation between **router, commands, specialists, skills, and playbooks**. That should be preserved.

The best evolution is not to replace the system, but to make it more explicit, faster to invoke, more production-aware, and more reusable for backend/microservices/DevOps reality.

That is what this manual does.

---

## Suggested next artifact to create from this manual

The highest-value next step is to generate a second artifact:

**`COMMANDS-RAPIDOS.md`**
- one screen per command
- full prompt
- lite prompt
- when to use
- agents involved
- output expected
- red flags
