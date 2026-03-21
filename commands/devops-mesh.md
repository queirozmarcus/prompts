---
name: devops-mesh
description: "Configurar e gerenciar service mesh (Istio/Linkerd). Orquestra Service Mesh Engineer com Kubernetes Engineer."
argument-hint: "[serviço-ou-namespace]"
---

# Service Mesh: $ARGUMENTS

Configure ou otimize service mesh para **$ARGUMENTS**.

## Instruções

### Step 1: Análise

Use o sub-agente **service-mesh-engineer** para:
- Avaliar necessidade de mesh (mTLS, traffic management, observability)
- Se mesh existente: auditar configuração atual
- Se novo: recomendar Istio vs Linkerd com trade-offs

### Step 2: Configuração

Ainda com **service-mesh-engineer**:
- VirtualService e DestinationRule para o serviço
- mTLS (STRICT mode) entre serviços
- Traffic management: canary, circuit breaking, retries, timeouts
- AuthorizationPolicy (quem pode falar com quem)

### Step 3: Validação

Use o sub-agente **kubernetes-engineer** para:
- Verificar sidecar injection no namespace
- Validar que probes funcionam com mesh
- Verificar resource overhead do sidecar
- Testar conectividade entre serviços

### Step 4: Apresentar

1. Configuração gerada (VirtualService, DestinationRule, AuthorizationPolicy)
2. Canary deployment strategy (se aplicável)
3. Métricas de mesh habilitadas
4. Impacto em latência e recursos
