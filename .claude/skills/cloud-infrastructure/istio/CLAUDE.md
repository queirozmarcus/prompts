# Skill: Istio

## Scope

Service mesh com Istio para gerenciamento de tráfego, segurança mTLS, observabilidade e resiliência em Kubernetes. Cobre VirtualServices, DestinationRules, Gateways, PeerAuthentication, circuit breaking, fault injection e integração com Kiali/Jaeger/Prometheus. Aplicável quando desenhando estratégias de tráfego (canary, A/B, blue-green) ou configurando segurança de comunicação inter-serviços.

## Core Principles

- **mTLS por padrão** — comunicação entre serviços deve ser encriptada e autenticada; PERMISSIVE apenas durante migração
- **Traffic policies são declarativas** — VirtualService e DestinationRule em Git, não mudanças manuais
- **Observabilidade integrada** — Istio injeta métricas, traces e logs automaticamente; instrumentar o mesh, não só o app
- **Fail open vs fail closed** — circuit breakers evitam cascade failures; configurar com thresholds realistas
- **Sidecar injection controlada** — habilitar por namespace com label, não globalmente

## VirtualServices & DestinationRules

**Pair obrigatório** — VirtualService sem DestinationRule para subsets causa erros:

```yaml
# DestinationRule — define subsets (versões) e políticas de conexão
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
  namespace: production
spec:
  host: myapp.production.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: UPGRADE
        idleTimeout: 30s
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 10s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
    - name: v1
      labels:
        version: "1.0"
    - name: v2
      labels:
        version: "2.0"
---
# VirtualService — controla roteamento
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
  namespace: production
spec:
  hosts:
    - myapp.production.svc.cluster.local
  http:
    - route:
        - destination:
            host: myapp.production.svc.cluster.local
            subset: v1
          weight: 90
        - destination:
            host: myapp.production.svc.cluster.local
            subset: v2
          weight: 10
```

## Traffic Management

**Canary deployment (10% → 100%):**
```yaml
# Fase 1: 10% canary
http:
  - route:
      - destination:
          host: myapp
          subset: stable
        weight: 90
      - destination:
          host: myapp
          subset: canary
        weight: 10
```

```bash
# Aumentar gradualmente
# Fase 2: 50%
kubectl patch vs myapp -n production --type='json' \
  -p='[{"op": "replace", "path": "/spec/http/0/route/0/weight", "value": 50},
       {"op": "replace", "path": "/spec/http/0/route/1/weight", "value": 50}]'
```

**A/B testing baseado em header:**
```yaml
http:
  - match:
      - headers:
          x-user-group:
            exact: beta-users
    route:
      - destination:
          host: myapp
          subset: v2
  - route:
      - destination:
          host: myapp
          subset: v1
```

**Blue-green (swap instantâneo):**
```yaml
# Trocar 100% do tráfego de blue para green
http:
  - route:
      - destination:
          host: myapp
          subset: green  # Alternar entre 'blue' e 'green'
        weight: 100
```

**Retries e timeouts:**
```yaml
http:
  - timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 3s
      retryOn: 5xx,gateway-error,connect-failure
    route:
      - destination:
          host: myapp
```

## mTLS & Security Policies

**STRICT mTLS por namespace (recomendado para produção):**
```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT    # Rejeita conexões não-TLS
```

**Migração: PERMISSIVE → STRICT:**
```bash
# 1. Habilitar PERMISSIVE (aceita mTLS e plaintext)
# 2. Verificar que sidecars injetados em todos os pods
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# 3. Verificar comunicação no Kiali (procurar edges sem cadeado)
# 4. Mudar para STRICT depois que todos os pods têm sidecar
```

**AuthorizationPolicy — controle de acesso L7:**
```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  selector:
    matchLabels:
      app: backend
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/production/sa/frontend"]
      to:
        - operation:
            methods: ["GET", "POST"]
            paths: ["/api/*"]
```

## Circuit Breaking & Fault Injection

**Circuit breaker via DestinationRule:**
```yaml
spec:
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 5      # 5 erros 5xx consecutivos
      consecutiveGatewayErrors: 5  # Ou 5 gateway errors
      interval: 10s                # Janela de análise
      baseEjectionTime: 30s        # Tempo mínimo fora do pool
      maxEjectionPercent: 50       # Max 50% dos hosts podem ser ejetados
    connectionPool:
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 200
      tcp:
        maxConnections: 100
        connectTimeout: 3s
```

**Fault Injection para testes de resiliência (staging only):**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp-chaos
  namespace: staging
spec:
  hosts: [myapp]
  http:
    - fault:
        delay:
          percentage:
            value: 10
          fixedDelay: 500ms   # 10% das requisições com 500ms delay
        abort:
          percentage:
            value: 5
          httpStatus: 503     # 5% das requisições retornam 503
      route:
        - destination:
            host: myapp
```

## Observability

**Métricas Istio no Prometheus:**
```promql
# Request rate por serviço
sum(rate(istio_requests_total{destination_service_namespace="production"}[5m])) by (destination_service_name)

# Error rate
sum(rate(istio_requests_total{destination_service_namespace="production",response_code=~"5.."}[5m]))
/ sum(rate(istio_requests_total{destination_service_namespace="production"}[5m]))

# P99 latency
histogram_quantile(0.99, sum(rate(istio_request_duration_milliseconds_bucket{destination_service_namespace="production"}[5m])) by (le, destination_service_name))
```

**Kiali — visualização do service mesh:**
```bash
# Port-forward para Kiali
kubectl port-forward svc/kiali -n istio-system 20001:20001

# Verificar health do mesh
istioctl analyze -n production

# Verificar configuração de proxy em pod específico
istioctl proxy-config cluster pod/myapp-xxx.production

# Sync de configuração
istioctl proxy-status
```

## Gateway Configuration

**Ingress Gateway para tráfego externo:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: SIMPLE
        credentialName: api-tls  # Secret com TLS cert
      hosts:
        - api.example.com
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api
  namespace: production
spec:
  hosts:
    - api.example.com
  gateways:
    - istio-system/main-gateway
    - mesh            # Também aplica no mesh interno
  http:
    - route:
        - destination:
            host: myapp.production.svc.cluster.local
            port:
              number: 80
```

## Common Mistakes / Anti-Patterns

- **VirtualService sem DestinationRule para subsets** — "subset not found" no envoy; sempre criar DR antes de VS com subsets
- **PERMISSIVE mTLS em produção** — aceita conexões não autenticadas; migrar para STRICT
- **Labels `version` faltando nos pods** — subsets do DestinationRule não funcionam sem labels correspondentes
- **Não verificar sidecar injection** — pods sem sidecar ficam fora do mesh silenciosamente
- **Fault injection em produção** — causar falhas reais em ambiente produtivo
- **Retries sem idempotência** — retry de operações não-idempotentes (POST com efeitos) causa duplicatas
- **Sem timeout definido** — requisições penduradas consomem conexões indefinidamente
- **Ignorar `istioctl analyze`** — detecta configurações inválidas antes de aplicar

## Communication Style

Quando esta skill está ativa:
- Sempre fornecer DestinationRule junto com VirtualService (se usar subsets)
- Alertar sobre impacto de mTLS STRICT em pods sem sidecar
- Distinguir configurações de staging (fault injection, chaos) de produção
- Mencionar métricas Prometheus disponíveis para monitorar mudanças de tráfego

## Expected Output Quality

- VirtualService e DestinationRule como par, nunca isolados se usar subsets
- Comandos `istioctl` para verificar configuração aplicada
- PromQL para monitorar o tráfego após mudanças
- Distinção clara entre PERMISSIVE (migração) e STRICT (produção)

---
**Skill type:** Passive
**Applies with:** kubernetes, observability, security
**Pairs well with:** k8s-platform-agent, gitops-agent, personal-engineering-agent
