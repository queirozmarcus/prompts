# DevOps Team — Claude Code Agents

## Visão Geral

Equipe de sub-agentes DevOps/Platform/SRE para operação de microsserviços Java/Spring Boot em Kubernetes multi-cloud. Cobre IaC, CI/CD, GitOps, observabilidade, segurança de infra, service mesh, FinOps e SRE.

**Integração:** Complementar ao Dev Team (`/dev-*`) e QA Team (`/qa-*`). Devs implementam → QA valida → DevOps entrega e opera.

## A Equipe

| Agente | Especialidade |
|--------|---------------|
| **DevOps Lead** | Estratégia de plataforma, padrões, decisões de infra |
| **IaC Engineer** | Terraform/OpenTofu, módulos, state, multi-cloud provisioning |
| **CI/CD Engineer** | Pipelines, quality gates, build, deploy |
| **Kubernetes Engineer** | Clusters, workloads, networking, storage, autoscaling, spot |
| **Observability Engineer** | Prometheus, Grafana, Loki, Datadog, alertas, SLOs, dashboards |
| **Security Ops Engineer** | Vault, secrets, network policies, RBAC, scanning, compliance |
| **Service Mesh Engineer** | Istio/Linkerd, mTLS, traffic management, canary |
| **SRE Engineer** | Incident response, postmortems, chaos engineering, DR |
| **AWS Cloud Engineer** | AWS services: EKS, ECS, RDS, ALB, IAM, VPC, Step Functions |
| **FinOps Engineer** | Cost optimization, rightsizing, Savings Plans, waste elimination |
| **GitOps Engineer** | ArgoCD/FluxCD, progressive delivery, Argo Rollouts |

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/devops-provision` | Provisionar infra para novo serviço (IaC + K8s + CI/CD + Observability) |
| `/devops-pipeline` | Criar/otimizar pipeline CI/CD completo |
| `/devops-observe` | Configurar observabilidade completa (métricas, logs, traces, alertas) |
| `/devops-incident` | Guiar resposta a incidente e gerar postmortem |
| `/devops-audit` | Auditoria de infra: segurança, custo, resiliência, compliance |
| `/devops-dr` | Planejar e validar disaster recovery |
| `/devops-finops` | Análise de custo e otimização FinOps |
| `/devops-gitops` | Configurar GitOps com ArgoCD/FluxCD |

## Cloud Providers Suportados

| Provider | Serviços Gerenciados |
|----------|---------------------|
| **AWS** | EKS, ECR, RDS, ElastiCache, MSK, Secrets Manager, CloudWatch, S3, ALB |
| **GCP** | GKE, Artifact Registry, Cloud SQL, Memorystore, Cloud Pub/Sub |
| **Azure** | AKS, ACR, Azure SQL, Azure Cache, Event Hubs, Key Vault |
| **Agnostic** | Kubernetes, Terraform, Helm, ArgoCD, Vault, Prometheus |

## Stack de Ferramentas

```
IaC:            Terraform / OpenTofu
GitOps:         ArgoCD / FluxCD
Service Mesh:   Istio / Linkerd
Secrets:        HashiCorp Vault / cloud-native (Secrets Manager, Key Vault)
Observability:  Prometheus + Grafana + Loki (OSS) | Datadog / New Relic (SaaS)
CI/CD:          GitHub Actions / GitLab CI / Jenkins
Containers:     Docker, Kubernetes, Helm
Registry:       ECR / Artifact Registry / ACR / Harbor
```

## Convenções

```
Terraform:     infra/{cloud}/{environment}/{component}/
Helm:          helm/{serviço}/
Pipelines:     .github/workflows/ | .gitlab-ci.yml
K8s manifests: k8s/{environment}/{serviço}/
ArgoCD apps:   argocd/applications/
Alertas:       monitoring/alerts/{serviço}.yml
Dashboards:    monitoring/dashboards/{serviço}.json
Runbooks:      docs/devops/runbooks/{serviço}.md
```

## Artefatos

```
docs/devops/
  runbooks/           → Guias operacionais por serviço
  iac/                → Decisões e diagramas de infra
  slos/               → SLO definitions por serviço
  postmortems/        → Postmortems de incidentes
  disaster-recovery/  → DR plans e procedimentos
```
