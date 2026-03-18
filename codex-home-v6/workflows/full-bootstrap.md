
# Full Bootstrap: $ARGUMENTS

Crie um microsserviço **completo e pronto para produção** em uma única execução, orquestrando os 3 packs (Dev + QA + DevOps).

## Instruções

Execute os passos na ordem — cada um depende do anterior.

### Step 1: Arquitetura e Código (Dev Pack)

Use o subagente **architect** para:
- Definir responsabilidade do serviço (1 frase)
- Definir comunicação com outros serviços
- Gerar ADR-001 da criação

Use o subagente **backend-dev** para:
- Criar estrutura hexagonal completa de pacotes
- Criar application.yml com profiles (local, staging, prod)
- GlobalExceptionHandler com Problem Details
- Spring Actuator (health, metrics, prometheus)
- Graceful shutdown + logback JSON
- Um use case placeholder com implementação mínima

Use o subagente **api-designer** para:
- Documentar endpoints base com OpenAPI annotations
- Placeholder de endpoint REST com request/response schemas

Use o subagente **dba** para:
- V1__init_schema.sql com tabelas iniciais
- Outbox table se for producer Kafka
- Índices para queries esperadas

### Step 2: Qualidade (QA Pack)

Use o subagente **unit-test-engineer** para:
- Criar teste unitário do use case placeholder
- Criar fixtures base (Object Mother)

Use o subagente **integration-test-engineer** para:
- Configurar BaseIntegrationTest com Testcontainers (PostgreSQL + Kafka + Redis)
- Criar teste de integração do repository
- Validar que migrations Flyway rodam

Use o subagente **qa-lead** para:
- Definir estratégia de testes inicial (mínimos para primeira release)
- Definir quality gates no CI

### Step 3: Infraestrutura (DevOps Pack)

Use o subagente **devops-engineer** (ou **cicd-engineer** se disponível) para:
- Criar Dockerfile (multi-stage, non-root, layered)
- Criar docker-compose.yml (app + postgres + redis + kafka)
- Criar pipeline CI/CD (build → test → quality gate → security scan → image → deploy)

Use o subagente **kubernetes-engineer** para:
- Criar Helm chart (deployment, service, configmap, hpa, pdb, serviceaccount)
- Configurar probes (liveness, readiness, startup)
- Configurar resources, graceful shutdown, topology spread

Use o subagente **observability-engineer** para:
- Configurar ServiceMonitor para Prometheus
- Definir alertas mínimos (error rate, latência, restarts)
- Sugerir dashboard Grafana

Use o subagente **security-ops** para:
- Criar NetworkPolicy base
- Criar ServiceAccount com least privilege
- Configurar Pod Security context (non-root, read-only FS)

### Step 4: Documentação

Gere os seguintes artefatos:
- `docs/architecture/adr/ADR-001-create-{service}.md`
- `docs/devops/runbooks/{service}.md` (runbook operacional)
- `docs/devops/slos/{service}.md` (SLOs iniciais)
- README.md do serviço

### Step 5: Apresentar resumo

1. **Árvore de arquivos** gerada (tree completo)
2. **Como rodar local:** `docker-compose up`
3. **Como rodar testes:** `./mvnw test`
4. **Como deployar:** resumo do pipeline
5. **Quality gates** configurados
6. **SLOs** definidos
7. **Próximos passos** recomendados (primeira feature, primeiro deploy)
