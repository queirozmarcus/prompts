
# Bootstrap: $ARGUMENTS-service

Crie um microsserviço novo chamado **$ARGUMENTS-service** com toda a estrutura pronta para produção.

## Instruções

### Step 1: Definição arquitetural

Use o subagente **architect** para:
- Definir responsabilidade do serviço (1 frase)
- Definir comunicação com outros serviços (sync/async)
- Definir ownership de dados
- Gerar ADR-001: criação do serviço

### Step 2: Estrutura do projeto

Use o subagente **backend-dev** para criar:
- Estrutura hexagonal de pacotes completa
- application.yml com profiles (local, staging, prod)
- GlobalExceptionHandler com Problem Details
- Spring Actuator configurado (health, metrics, prometheus)
- Graceful shutdown
- Logback com JSON structured logging
- Um use case placeholder com test

### Step 3: Schema inicial

Use o subagente **dba** para:
- V1__init_schema.sql com tabelas iniciais
- Outbox table se for producer Kafka
- Índices iniciais

### Step 4: API base

Use o subagente **api-designer** para:
- Health/info endpoints documentados
- Placeholder de endpoint REST com OpenAPI

### Step 5: Infraestrutura

Use o subagente **devops-engineer** para:
- Dockerfile (multi-stage, non-root)
- docker-compose.yml (app + postgres + redis + kafka)
- Helm chart base (deployment, service, configmap, hpa, pdb)
- Pipeline CI/CD (build → test → quality gate → image → deploy)

### Step 6: Apresentar

1. Árvore de arquivos gerada
2. Como rodar localmente: `docker-compose up`
3. Como rodar testes: `./mvnw test`
4. ADR documentando decisões
5. Instrução: "Execute o workflow `qa-audit` para verificar qualidade" (integração com QA team)
