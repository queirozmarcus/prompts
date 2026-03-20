# Skill: ArgoCD

## Scope

GitOps continuous delivery com ArgoCD. Cobre Application CRDs, sync policies, App of Apps pattern, RBAC, notificações, health checks customizados, Image Updater e integração com Helm/Kustomize. Aplicável quando gerenciando deployments via ArgoCD ou desenhando workflows GitOps.

## Core Principles

- **Git é a fonte de verdade** — o estado do cluster deve refletir exatamente o que está no repositório Git
- **Sync policies com cuidado** — auto-sync + prune em produção é perigoso; entender o que prune faz antes de habilitar
- **AppProjects para isolamento** — cada team/ambiente deve ter seu AppProject com source/destination restritos
- **Auditabilidade** — cada mudança no cluster tem um commit e um sync event rastreável
- **Health checks** — ArgoCD só considera um app "Healthy" quando todos os recursos estão prontos

## Application Configuration

**Application CRD básica:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-production
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io  # Deleta recursos ao deletar Application
spec:
  project: production
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    targetRevision: main
    path: apps/myapp/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - ApplyOutOfSyncOnly=true
```

**Application com Helm:**
```yaml
spec:
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: postgresql
    targetRevision: "13.2.0"
    helm:
      releaseName: postgresql
      valueFiles:
        - values-production.yaml
      parameters:
        - name: primary.resources.requests.memory
          value: "512Mi"
```

**Application com Kustomize:**
```yaml
spec:
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    path: apps/myapp
    targetRevision: main
    kustomize:
      images:
        - myapp=registry/myapp:1.2.3
```

## Sync Policies & Strategies

**Sync policies — progressão recomendada:**
```yaml
# Development: auto-sync total
syncPolicy:
  automated:
    prune: true      # Remove recursos deletados do Git
    selfHeal: true   # Reverte mudanças manuais no cluster

# Staging: auto-sync sem prune
syncPolicy:
  automated:
    prune: false     # Recursos extras não são removidos automaticamente
    selfHeal: true

# Production: MANUAL sync
syncPolicy: {}       # Requer sync manual ou aprovação
# Ou: sync automático apenas em janelas de manutenção
```

**`prune: true` — entender antes de usar:**
- Remove recursos do cluster quando deletados do Git
- Perigoso se branch errada ou commit acidental
- Em produção: preferir sync manual ou gates de aprovação

**Sync Options úteis:**
```yaml
syncOptions:
  - CreateNamespace=true           # Criar namespace se não existir
  - ApplyOutOfSyncOnly=true        # Só aplica recursos que diferem (mais rápido)
  - PrunePropagationPolicy=foreground  # Aguarda deletion antes de continuar
  - RespectIgnoreDifferences=true  # Respeita ignoreDifferences abaixo
  - ServerSideApply=true           # Usa SSA ao invés de CSR (melhor para CRDs)
```

## App of Apps Pattern

**Bootstrap de cluster inteiro:**
```yaml
# apps/bootstrap.yaml — Application que gerencia outras Applications
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bootstrap
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    targetRevision: main
    path: argocd/apps    # Diretório com todos os Application yamls
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Estrutura do repositório:**
```
k8s-manifests/
├── argocd/
│   └── apps/
│       ├── myapp-production.yaml
│       ├── myapp-staging.yaml
│       └── monitoring.yaml
└── apps/
    ├── myapp/
    │   ├── production/
    │   │   ├── deployment.yaml
    │   │   └── service.yaml
    │   └── staging/
    └── monitoring/
```

## RBAC & Access Control

**AppProject — isolamento por team/ambiente:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  description: Production environment
  sourceRepos:
    - https://github.com/org/k8s-manifests.git
  destinations:
    - namespace: production
      server: https://kubernetes.default.svc
  # Bloquear recursos cluster-level (ClusterRole, etc.)
  clusterResourceWhitelist: []
  namespaceResourceBlacklist:
    - group: ""
      kind: ResourceQuota
  # Sync windows — permitir sync apenas em horários aprovados
  syncWindows:
    - kind: allow
      schedule: "0 9-17 * * 1-5"  # Seg-Sex, 9h-17h
      duration: 8h
      applications: ["*"]
```

**RBAC em `argocd-rbac-cm`:**
```yaml
data:
  policy.csv: |
    # Admins podem tudo
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow

    # Developers podem sync mas não deletar
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, production/*, allow
    p, role:developer, applications, action/*, staging/*, allow

    # Binding de grupos OIDC
    g, org:platform-team, role:admin
    g, org:backend-team, role:developer
  policy.default: role:readonly
```

## Notifications & Alerts

**Configuração de notificação para Slack:**
```yaml
# argocd-notifications-cm
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-sync-failed: |
    message: |
      Application {{.app.metadata.name}} sync failed.
      Error: {{.app.status.operationState.message}}
    slack:
      attachments: |
        [{
          "color": "danger",
          "title": "{{.app.metadata.name}}",
          "title_link": "{{.context.argocdUrl}}/applications/{{.app.metadata.name}}"
        }]
  trigger.on-sync-failed: |
    - description: Application sync failed
      send: [app-sync-failed]
      when: app.status.operationState.phase in ['Error', 'Failed']
```

**Annotations em Application para ativar notificações:**
```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-failed.slack: production-alerts
    notifications.argoproj.io/subscribe.on-health-degraded.slack: production-alerts
```

## Health Checks & Custom Health Assessments

**Health checks customizados para CRDs (Lua):**
```yaml
# argocd-cm
data:
  resource.customizations.health.cert-manager.io_Certificate: |
    hs = {}
    if obj.status ~= nil then
      if obj.status.conditions ~= nil then
        for i, condition in ipairs(obj.status.conditions) do
          if condition.type == "Ready" and condition.status == "False" then
            hs.status = "Degraded"
            hs.message = condition.message
            return hs
          end
          if condition.type == "Ready" and condition.status == "True" then
            hs.status = "Healthy"
            hs.message = condition.message
            return hs
          end
        end
      end
    end
    hs.status = "Progressing"
    hs.message = "Waiting for certificate"
    return hs
```

## Image Updater

**Atualizações automáticas de imagem:**
```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=registry/myapp
    argocd-image-updater.argoproj.io/myapp.update-strategy: semver
    argocd-image-updater.argoproj.io/myapp.allow-tags: regexp:^1\.\d+\.\d+$
    # Write-back ao Git (preferir sobre ArgoCD annotation)
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
```

## Common Mistakes / Anti-Patterns

- **Auto-sync + prune em produção sem sync windows** — risco de remoção acidental de recursos
- **Sem AppProject** — todos os apps no `default` project sem restrições de source/destination
- **Segredos em Git (mesmo encriptados inline)** — usar External Secrets Operator + AWS Secrets Manager
- **`selfHeal: true` em prod sem alertas** — mudanças manuais revertidas silenciosamente
- **Sem finalizer no Application** — deletar Application não deleta os recursos no cluster
- **App sem health checks** — ArgoCD reporta "Healthy" quando recursos ainda estão crashando
- **Destino sem namespace** — apps deploiam no namespace errado ou no `default`
- **Sync manual sem revisão** — clicar "Sync" sem revisar o diff antes

## Communication Style

Quando esta skill está ativa:
- Sempre especificar o `project` ao criar Applications
- Destacar riscos de `prune: true` antes de habilitá-lo
- Mostrar o diff de sync antes de aplicar mudanças
- Referenciar AppProject quando falar de isolamento e RBAC

## Expected Output Quality

- Application YAML completos com todos os campos relevantes
- Estrutura de repositório GitOps clara e versionável
- RBAC policy.csv funcional e testável com `argocd auth can-i`
- Distinção entre sync policies por ambiente (dev vs staging vs prod)

---
**Skill type:** Passive
**Applies with:** kubernetes, git, helm, github-actions
**Pairs well with:** gitops-engineer (DevOps pack), kubernetes-engineer (DevOps pack), architect (Dev pack)
