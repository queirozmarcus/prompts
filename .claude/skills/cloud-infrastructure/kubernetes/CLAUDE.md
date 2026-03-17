# Skill: Kubernetes

## Scope

Design, deploy e operação de workloads em Kubernetes (EKS e outros). Cobre pods, deployments, StatefulSets, services, ingress, RBAC, resource management, Helm, HPA/VPA, observabilidade e troubleshooting. Aplicável quando trabalhando com manifests K8s, EKS clusters, ou qualquer operação de orquestração de containers.

## Core Principles

- **Declarative always** — manifests em Git são a fonte de verdade; nunca mutações manuais em prod
- **Resource limits obrigatórios** — sem limits, um pod pode consumir o cluster inteiro (noisy neighbor)
- **Health checks em todos os containers** — liveness e readiness probes são requisitos, não opcionais
- **Least privilege para workloads** — ServiceAccounts com RBAC mínimo; nunca usar `default` SA
- **Graceful shutdown** — containers devem lidar com SIGTERM e drenar conexões antes de terminar
- **Namespaces como fronteiras** — separar por equipe/ambiente, aplicar ResourceQuotas e NetworkPolicies

## Pod & Container Design

**Spec mínima de produção:**
```yaml
spec:
  containers:
    - name: app
      image: myapp:1.2.3          # Sempre tag imutável, NUNCA latest
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "500m"
          memory: "256Mi"
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 30
        periodSeconds: 10
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 3
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
  terminationGracePeriodSeconds: 60
  serviceAccountName: myapp       # Nunca usar o default SA
```

**init containers — para inicialização ordenada:**
```yaml
initContainers:
  - name: wait-for-db
    image: busybox:1.36
    command: ['sh', '-c', 'until nc -z postgres 5432; do sleep 2; done']
  - name: run-migrations
    image: myapp:1.2.3
    command: ['./migrate', 'up']
    envFrom:
      - secretRef:
          name: app-secrets
```

## Workload Resources

**Deployment (stateless — APIs, web apps):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: "1.2.3"
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: myapp
                topologyKey: topology.kubernetes.io/zone
```

**Escolha de workload:**
- `Deployment` — stateless (APIs, workers, web)
- `StatefulSet` — stateful (databases, queues, Kafka); identidade estável, PVCs persistentes
- `DaemonSet` — um pod por node (log agents, monitoring, network plugins)
- `Job` / `CronJob` — batch e tarefas agendadas

## Service & Networking

**Types de Service:**
```yaml
# ClusterIP (padrão) — apenas tráfego interno ao cluster
apiVersion: v1
kind: Service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
    - name: http
      port: 80
      targetPort: 8080
```

- `ClusterIP` — tráfego interno; descoberta via `myapp.namespace.svc.cluster.local`
- `NodePort` — dev/testing; evitar em produção
- `LoadBalancer` — cria ALB/NLB por serviço (caro no AWS; preferir Ingress)
- `ExternalName` — DNS alias para serviço externo

## Ingress & Load Balancing

**NGINX Ingress Controller:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp
                port:
                  number: 80
  tls:
    - hosts: [api.example.com]
      secretName: api-tls
```

**AWS Load Balancer Controller** — cria ALBs nativos por Ingress. Melhor integração com ACM, WAF, e target groups para EKS.

## RBAC & Security

**ServiceAccount dedicado por workload:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/myapp-irsa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
    resourceNames: ["myapp-config"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp
  namespace: production
subjects:
  - kind: ServiceAccount
    name: myapp
roleRef:
  kind: Role
  name: myapp
  apiGroup: rbac.authorization.k8s.io
```

**NetworkPolicy — deny-all por padrão, permitir explicitamente:**
```yaml
# Deny all ingress and egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# Permitir ingress apenas do ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-controller
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - port: 8080
```

## Resource Management

**Requests vs Limits:**
- `requests` — o que o pod precisa (usado pelo scheduler para alocar no node)
- `limits` — o máximo permitido (CPU: throttling; Memory: OOMKill)
- Regra prática: `limits.memory = 2x requests.memory`; `limits.cpu = 2-5x requests.cpu`

**LimitRange (defaults para namespace):**
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: namespace-defaults
  namespace: production
spec:
  limits:
    - type: Container
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      default:
        cpu: "500m"
        memory: "256Mi"
      max:
        cpu: "4"
        memory: "8Gi"
```

**ResourceQuota (por namespace/team):**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "40Gi"
    limits.cpu: "40"
    limits.memory: "80Gi"
    pods: "50"
    services.loadbalancers: "0"   # Forçar uso de Ingress
```

## Helm Best Practices

```bash
# Instalar com versão pinada e values explícitos
helm install myapp ./chart \
  --namespace production \
  --values values-production.yaml \
  --version 1.2.3 \
  --atomic \        # Rollback automático se deploy falhar
  --timeout 10m

# Upgrade com dry-run antes
helm diff upgrade myapp ./chart --values values-production.yaml  # helm-diff plugin
helm upgrade myapp ./chart --values values-production.yaml \
  --atomic --timeout 10m

# Debug de rendering
helm template myapp ./chart --values values-production.yaml | kubectl apply --dry-run=server -f -
```

## Health Checks & Probes

```yaml
livenessProbe:   # Reinicia container se falhar (travado?)
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:  # Remove do Service se falhar (pronto?)
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3

startupProbe:    # Substitui liveness durante startup lento
  httpGet:
    path: /health/startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10  # 30 * 10s = 5 minutos máximo para startup
```

## Rolling Updates & Rollbacks

```bash
# Monitorar rollout (aguarda até completion ou timeout)
kubectl rollout status deployment/myapp -n production --timeout=10m

# Histórico de rollouts
kubectl rollout history deployment/myapp -n production

# Rollback para revisão anterior
kubectl rollout undo deployment/myapp -n production

# Rollback para revisão específica
kubectl rollout undo deployment/myapp --to-revision=3 -n production

# Pausar rollout (canary manual)
kubectl rollout pause deployment/myapp -n production
# ... validar metrics ...
kubectl rollout resume deployment/myapp -n production
```

**PodDisruptionBudget — protege durante node drains e upgrades:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2   # Ou: maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

## Observability & Debugging

```bash
# Logs em tempo real
kubectl logs -f deployment/myapp -n production --tail=100

# Logs de container específico (pod multi-container)
kubectl logs pod/myapp-xxx -c sidecar -n production

# Eventos recentes (errors, warnings, scheduling)
kubectl get events -n production --sort-by='.lastTimestamp' | tail -30

# Describe — debug de scheduling, probes, image pulls
kubectl describe pod myapp-xxx -n production

# Exec para troubleshooting interativo
kubectl exec -it deployment/myapp -n production -- sh

# Resource usage em tempo real
kubectl top pods -n production --sort-by=memory
kubectl top nodes

# Port-forward para debug local sem expor serviço
kubectl port-forward svc/myapp 8080:80 -n production

# Verificar RBAC — o que este SA pode fazer?
kubectl auth can-i --list --as=system:serviceaccount:production:myapp
```

## Common Mistakes / Anti-Patterns

- **`image: latest`** — tag imutável; sempre usar versão semântica ou SHA digest
- **Sem resource limits** — OOMKill sem warning, noisy neighbor, cluster instável
- **Sem readiness probe** — tráfego chega antes do app estar pronto → erros durante deploy
- **Sem PodDisruptionBudget** — node drain remove todos os pods de uma vez
- **Default ServiceAccount** — tem permissões default e acessa kube-apiserver; criar SA específico
- **Secrets como env vars planos** — aparecem em `kubectl describe pod`; usar `secretKeyRef`
- **Replicas = 1 em produção** — single point of failure; mínimo 2 para HA
- **Sem podAntiAffinity** — todos os replicas no mesmo node → node failure = outage total
- **`kubectl apply` direto em produção** — usar GitOps (ArgoCD) para auditabilidade
- **Sem namespace isolamento** — tudo em `default` mistura times e dificulta RBAC e quota

## Communication Style

Quando esta skill está ativa:
- Fornecer manifests YAML completos com `namespace` explícito
- Mencionar implicações de segurança (privileged, hostNetwork, hostPID)
- Distinguir comandos destrutivos (`delete`, `drain`) de read-only (`get`, `describe`)
- Indicar quando mudança requer rollout vs restart vs nenhum downtime

## Expected Output Quality

- YAML manifests válidos e aplicáveis com `kubectl apply -f`
- Comandos kubectl com namespace e contexto explícitos
- Análise de blast radius antes de mudanças em produção
- Troubleshooting steps progressivos: `get` → `describe` → `logs` → `exec`

---
**Skill type:** Passive
**Applies with:** aws, argocd, istio, observability, security, finops
**Pairs well with:** k8s-platform-agent, gitops-agent, personal-engineering-agent
