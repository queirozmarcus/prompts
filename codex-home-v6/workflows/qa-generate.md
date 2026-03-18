
# Geração de Testes: $ARGUMENTS

Gere testes completos para **$ARGUMENTS** cobrindo unitários e integração.

## Instruções

### Step 1: Analisar código alvo

Use o subagente **test-automation-engineer** para:
- Ler o código fonte de $ARGUMENTS
- Identificar: métodos públicos, regras de negócio, validações, edge cases, exceções
- Classificar: domain (sem mock) vs application (mock ports) vs adapter (Testcontainers)
- Mapear dependências (o que precisa de mock vs teste real)
- Listar cenários de teste priorizados por risco

### Step 2: Gerar testes unitários

Use o subagente **unit-test-engineer** para:
- Gerar testes unitários para cada cenário identificado
- Happy path + edge cases + exceções
- Fixtures reutilizáveis quando necessário
- @DisplayName descritivo em todo teste
- Given-When-Then structure

### Step 3: Gerar testes de integração (se aplicável)

Se $ARGUMENTS envolve persistência, messaging ou cache, use o subagente **integration-test-engineer** para:
- Gerar testes com Testcontainers
- Testar com infra real (PostgreSQL, Kafka, Redis)
- Cleanup entre testes

### Step 4: Verificar e apresentar

1. Liste todos os testes gerados com descrição
2. Indique cobertura estimada
3. Destaque cenários de risco que foram cobertos
4. Indique gaps restantes (se houver)
5. Instrua como executar: `./mvnw test -Dtest="{TestClass}"`
