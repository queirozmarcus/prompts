# ⚙️ DevOps Team — Claude Code Agents

Equipe de sub-agentes DevOps/Platform/SRE para operação de microsserviços em Kubernetes multi-cloud. Cobre IaC (Terraform), CI/CD (GitHub Actions + ArgoCD), observabilidade (Prometheus + Grafana + Loki), service mesh (Istio/Linkerd), secrets (Vault), segurança e SRE.

## A Equipe

| Agente | Cor | Especialidade |
|--------|-----|---------------|
| **DevOps Lead** | 🔵 | Estratégia de plataforma, FinOps, SLOs, capacity |
| **IaC Engineer** | 🟣 | Terraform/OpenTofu, multi-cloud, módulos, state |
| **CI/CD Engineer** | 🟢 | Pipelines, GitOps (ArgoCD/Flux), quality gates, canary |
| **Kubernetes Engineer** | 🔵 Cyan | Workloads, autoscaling, spot, networking, troubleshooting |
| **Observability Engineer** | 🟡 | Prometheus, Grafana, Loki, traces, alertas SLO-based |
| **Security Ops** | 🔴 | Vault, NetworkPolicy, RBAC, scanning, hardening |
| **Service Mesh Engineer** | 🟠 | Istio/Linkerd, mTLS, traffic management, canary |
| **SRE Engineer** | 🩷 | Incidents, postmortems, chaos engineering, DR, runbooks |

## Instalação

```bash
# No projeto
cp -r devops-team-agents/.claude/agents/* .claude/agents/
cp -r devops-team-agents/.claude/commands/* .claude/commands/
# Merge CLAUDE.md com existente ou copiar
mkdir -p docs/devops/{runbooks,iac,slos,postmortems,disaster-recovery}
```

Global:
```bash
cp -r devops-team-agents/.claude/agents/* ~/.claude/agents/
cp -r devops-team-agents/.claude/commands/* ~/.claude/commands/
```

## Slash Commands

### `/devops-provision order-service aws` — Provisionar infra
IaC + K8s + CI/CD + Observability + Security para serviço novo.

### `/devops-pipeline order-service` — Pipeline CI/CD
Criar ou otimizar pipeline com quality gates e security scans.

### `/devops-observe order-service` — Observabilidade
Prometheus + Grafana dashboard + alertas SLO-based + Loki + tracing.

### `/devops-incident "latência alta no order-service"` — Incident response
Diagnóstico guiado + mitigação + postmortem blameless.

### `/devops-audit` — Auditoria de infra
Segurança + custo + resiliência + compliance — score e action items.

### `/devops-dr order-service` — Disaster recovery
DR plan + game day + validação + estimativa de custo.

## Uso Direto

```
claude> Use o iac-engineer para criar módulo Terraform de EKS com Karpenter
claude> Use o cicd-engineer para configurar ArgoCD com canary rollouts
claude> Use o kubernetes-engineer para diagnosticar OOMKilled no payment-service
claude> Use o observability-engineer para criar dashboard Grafana do order-service
claude> Use o security-ops para hardening do cluster EKS
claude> Use o service-mesh-engineer para configurar Istio mTLS strict
claude> Use o sre-engineer para planejar game day de failover de banco
claude> Use o devops-lead para análise FinOps do mês
```

### Specialist-Only Agents

4 agentes nao possuem slash commands dedicados — sao especialistas invocados diretamente ou orquestrados por outros commands:

| Agente | Como invocar | Orquestrado por |
|--------|-------------|-----------------|
| `observability-engineer` | `Use o observability-engineer para...` | `/devops-provision`, `/devops-observe` |
| `service-mesh-engineer` | `Use o service-mesh-engineer para...` | Invocacao direta |
| `iac-engineer` | `Use o iac-engineer para...` | `/devops-provision` |
| `cicd-engineer` | `Use o cicd-engineer para...` | `/devops-pipeline`, `/devops-provision` |

## Integração com Dev Team + QA Team

Os 3 packs funcionam juntos — o fluxo completo de engenharia:

```
DEV TEAM                    QA TEAM                     DEVOPS TEAM
─────────                   ─────────                   ────────────
/dev-bootstrap     →        /qa-audit              →    /devops-provision
/dev-feature       →        /qa-generate           →    /devops-pipeline
/dev-review        →        /qa-review                  /devops-observe
/dev-refactor      →        /qa-performance             /devops-incident
/dev-api                    /qa-flaky                   /devops-audit
                                                        /devops-dr
```

Para combinar todos:
```bash
cp -r dev-team-agents/.claude/agents/* .claude/agents/
cp -r dev-team-agents/.claude/commands/* .claude/commands/
cp -r qa-team-agents/.claude/agents/* .claude/agents/
cp -r qa-team-agents/.claude/commands/* .claude/commands/
cp -r devops-team-agents/.claude/agents/* .claude/agents/
cp -r devops-team-agents/.claude/commands/* .claude/commands/
```

**Resultado: 23 agentes + 16 slash commands** — equipe completa de engenharia.

## Estrutura

```
.claude/
  agents/
    devops-lead.md              → Estratégia e FinOps
    iac-engineer.md             → Terraform multi-cloud
    cicd-engineer.md            → Pipelines e GitOps
    kubernetes-engineer.md      → Workloads e autoscaling
    observability-engineer.md   → Prometheus, Grafana, Loki
    security-ops.md             → Vault, RBAC, hardening
    service-mesh-engineer.md    → Istio/Linkerd
    sre-engineer.md             → Incidents, chaos, DR
  commands/
    devops-provision.md         → /devops-provision
    devops-pipeline.md          → /devops-pipeline
    devops-observe.md           → /devops-observe
    devops-incident.md          → /devops-incident
    devops-audit.md             → /devops-audit
    devops-dr.md                → /devops-dr

docs/devops/
  runbooks/          → Guias operacionais
  iac/               → Decisões e diagramas de infra
  slos/              → SLO definitions
  postmortems/       → Postmortems blameless
  disaster-recovery/ → DR plans
```

## Cloud Support

Todos os agentes suportam multi-cloud:
- **AWS**: EKS, ECR, RDS, ElastiCache, MSK, Secrets Manager, ALB
- **GCP**: GKE, Artifact Registry, Cloud SQL, Memorystore, Pub/Sub
- **Azure**: AKS, ACR, Azure SQL, Azure Cache, Event Hubs, Key Vault
- **Agnostic**: Kubernetes, Terraform, Helm, ArgoCD, Vault, Prometheus
