
# Testes E2E: $ARGUMENTS

Crie testes end-to-end para o fluxo **$ARGUMENTS**.

## Instruções

### Step 1: Mapear fluxo

Use o subagente **e2e-test-engineer** para:
- Identificar todos os endpoints envolvidos no fluxo $ARGUMENTS
- Mapear a sequencia de chamadas (ex: create order -> process payment -> confirm)
- Identificar serviços externos envolvidos e seus contratos
- Identificar pre-condicoes (dados de setup, estado inicial)

### Step 2: Criar testes de API

Ainda com **e2e-test-engineer**:
- **Happy path completo:** fluxo de ponta a ponta com validações em cada etapa
- **Error paths críticos:** falha de pagamento, dados inválidos, timeout de serviço externo
- **Smoke tests:** subset minimo para validar deploy (< 30s de execução)
- Usar RestAssured para testes de API
- Dados de teste isolados (create/teardown por teste)

### Step 3: Criar testes de UI (se aplicável)

Se $ARGUMENTS envolve frontend, com **e2e-test-engineer**:
- Playwright para testes de UI
- Page Object Model
- Screenshots em falha
- Apenas fluxos críticos (nao duplicar testes de API)

### Step 4: Configurar execução

Com **e2e-test-engineer**:
- docker-compose para ambiente de teste (serviços + deps)
- Script de execução com setup e teardown
- Integracao com CI pipeline (stage separado, apos deploy em staging)

### Step 5: Apresentar resumo

1. Lista de cenarios E2E criados
2. Cobertura de fluxos críticos
3. Smoke tests para validacao de deploy
4. Instruções para rodar: `./mvnw test -Dtest="*E2ETest"`
5. Tempo estimado de execução
