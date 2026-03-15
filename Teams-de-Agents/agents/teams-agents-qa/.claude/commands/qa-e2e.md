---
name: qa-e2e
description: "Criar testes end-to-end para um fluxo ou servico. Orquestra E2E Test Engineer."
argument-hint: "[fluxo-ou-servico]"
---

# Testes E2E: $ARGUMENTS

Crie testes end-to-end para o fluxo **$ARGUMENTS**.

## Instrucoes

### Step 1: Mapear fluxo

Use o sub-agente **e2e-test-engineer** para:
- Identificar todos os endpoints envolvidos no fluxo $ARGUMENTS
- Mapear a sequencia de chamadas (ex: create order -> process payment -> confirm)
- Identificar servicos externos envolvidos e seus contratos
- Identificar pre-condicoes (dados de setup, estado inicial)

### Step 2: Criar testes de API

Ainda com **e2e-test-engineer**:
- **Happy path completo:** fluxo de ponta a ponta com validacoes em cada etapa
- **Error paths criticos:** falha de pagamento, dados invalidos, timeout de servico externo
- **Smoke tests:** subset minimo para validar deploy (< 30s de execucao)
- Usar RestAssured para testes de API
- Dados de teste isolados (create/teardown por teste)

### Step 3: Criar testes de UI (se aplicavel)

Se $ARGUMENTS envolve frontend, com **e2e-test-engineer**:
- Playwright para testes de UI
- Page Object Model
- Screenshots em falha
- Apenas fluxos criticos (nao duplicar testes de API)

### Step 4: Configurar execucao

Com **e2e-test-engineer**:
- docker-compose para ambiente de teste (servicos + deps)
- Script de execucao com setup e teardown
- Integracao com CI pipeline (stage separado, apos deploy em staging)

### Step 5: Apresentar resumo

1. Lista de cenarios E2E criados
2. Cobertura de fluxos criticos
3. Smoke tests para validacao de deploy
4. Instrucoes para rodar: `./mvnw test -Dtest="*E2ETest"`
5. Tempo estimado de execucao
