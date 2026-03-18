
# Setup GitOps: $ARGUMENTS

Configure deploy GitOps para **$ARGUMENTS**.

## Instruções

### Step 1: Estrutura

Use o subagente **gitops-engineer** para:
- Definir estrutura do manifest repository
- Criar ArgoCD Application manifest
- Configurar sync policy (auto-sync, prune, self-heal)
- Configurar AppProject com RBAC

### Step 2: Progressive delivery

Ainda com **gitops-engineer**:
- Configurar Argo Rollouts para canary deployment
- Definir AnalysisTemplate com métricas de sucesso
- Configurar sync windows para produção

### Step 3: Pipeline integration

Use o subagente **cicd-engineer** para:
- Configurar Image Updater (write-back de image tag)
- Integrar pipeline CI com trigger de sync
- Configurar notifications (Slack on sync failure/degraded)

### Step 4: Apresentar

1. Manifest repository structure
2. ArgoCD Application + AppProject
3. Rollout strategy configurada
4. Pipeline integration
