
# Provisionar Infra: $ARGUMENTS

Provisione infraestrutura completa para o serviço especificado.

## Instruções

### Step 1: IaC — Use **iac-engineer** para:
- Criar/atualizar módulos Terraform (database, cache, messaging se necessário)
- Configurar IAM/service account com least privilege
- Configurar security groups / firewall rules

### Step 2: Kubernetes — Use **kubernetes-engineer** para:
- Criar Helm chart completo (deployment, service, configmap, hpa, pdb)
- Configurar probes, resources, graceful shutdown
- Configurar topology spread e spot tolerance

### Step 3: CI/CD — Use **cicd-engineer** para:
- Criar pipeline (build → test → quality gate → security → image → deploy)
- Configurar ArgoCD Application para GitOps
- Configurar environment promotion

### Step 4: Observability — Use **observability-engineer** para:
- Configurar ServiceMonitor para Prometheus
- Criar dashboard Grafana (RED method)
- Configurar alertas SLO-based
- Configurar log aggregation

### Step 5: Security — Use **security-ops** para:
- Configurar secrets via Vault ou cloud-native
- Criar NetworkPolicy
- Criar ServiceAccount + RBAC
- Configurar Pod Security Standards

### Step 6: Consolidar — Como **devops-lead**:
- Gerar runbook operacional
- Definir SLOs iniciais
- Estimar custo mensal
- Apresentar checklist de readiness

Instrução para o dev: "Execute o workflow `dev-bootstrap {serviço}` para gerar o código do serviço."
