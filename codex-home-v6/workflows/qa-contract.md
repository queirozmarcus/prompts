
# Contract Tests: $ARGUMENTS

Crie ou valide contract tests para **$ARGUMENTS**.

## Instruções

### Step 1: Analisar contratos existentes

Use o subagente **contract-test-engineer** para:
- Identificar APIs REST expostas por $ARGUMENTS (endpoints, schemas, status codes)
- Identificar eventos Kafka produzidos/consumidos por $ARGUMENTS
- Verificar se ja existem contract tests (Pact ou Spring Cloud Contract)
- Mapear dependencias: quem consome as APIs/eventos de $ARGUMENTS?

### Step 2: Gerar/atualizar contract tests

Ainda com **contract-test-engineer**:
- **REST contracts:** criar provider contract tests para cada endpoint
  - Happy path + error responses (400, 404, 409, 422)
  - Request/response schemas validados
  - Paginacao e filtros quando aplicavel
- **Kafka contracts:** criar schema contracts para cada evento
  - Schema versionado (v1, v2...)
  - Backward compatibility validation
  - Required fields + optional fields

### Step 3: Configurar verificacao

Com **contract-test-engineer**:
- Configurar contract verification no build (Maven/Gradle plugin)
- Configurar consumer-side verification para serviços dependentes
- Adicionar quality gate: deploy bloqueado se contract falhar

### Step 4: Apresentar resumo

1. Lista de contratos criados (REST + Kafka)
2. Servicos consumidores identificados
3. Instruções para rodar: `./mvnw test -Dtest="*ContractTest"`
4. Gaps restantes (contratos pendentes)
