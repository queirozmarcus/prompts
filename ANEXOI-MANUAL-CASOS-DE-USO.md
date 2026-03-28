# Manual Completo de Casos de Uso v10.2.0

> **ANEXO I** — Documento complementar ao [README.md](README.md). Para arquitetura interna, veja [ANEXO II](ANEXOII-ARQUITETURA.md). Para referência operacional, veja [ANEXO III](ANEXOIII-AI-OS-Brutal-Edition.md). Para capacidades dos agents, veja [ANEXO IV](ANEXOIV-AGENT-CAPABILITIES.md).
## Claude Code Agent Ecosystem — Guia Operacional

**37 agents · 31 commands · 28 skills · 13 playbooks · 7 plugins**

Este manual cobre **todos os cenários** que você vai encontrar no dia a dia como engenheiro backend Java/Spring Boot, com os comandos exatos para cada situação.

---

# PARTE 1 — INÍCIO DO DIA

## 1.1 Abrir sessão de trabalho

```bash
claude --agent marcus
```

Marcus faz varredura automática do projeto:
- Detecta tipo (Java/Maven, Node, Python)
- Identifica infra (Docker, Helm, Terraform, GitHub Actions)
- Conta agents, commands, plugins instalados
- Apresenta status em 3-5 linhas

**Exemplo de output do Marcus:**
```
Fala! 👋

Contexto do projeto:
  ☕ Java 21/Maven · Spring Boot 3.2 · 🐳 Docker + Compose · ⎈ Helm
  🗄️ PostgreSQL + Flyway · 📨 Kafka · 📋 CLAUDE.md presente
  🤖 37 agents · 31 commands · 7 plugins

Pronto pra trabalhar. O que precisa hoje?
```

## 1.2 Ver o que está disponível

```
> /agents                    # lista todos os agents
> /plugin list               # lista plugins instalados
> quais commands eu tenho?   # Marcus lista todos os 51 commands com exemplos
```

## 1.3 Entender um projeto novo

```
> me explique a arquitetura deste projeto
```

Marcus delega para o `architect` que analisa a estrutura de pacotes, dependências, padrões usados e gera um mapa do projeto.

## 1.4 Inicializar CLAUDE.md em projeto sem

```
> /init
```

Cria um CLAUDE.md com convenções do projeto detectadas automaticamente.

---

# PARTE 2 — DESENVOLVIMENTO DE FEATURES

## 2.1 Feature completa (do design ao review)

O cenário mais comum do dia a dia — implementar um requisito end-to-end.

```
> /dev-feature "adicionar endpoint de busca de pedidos por período com filtros de status e paginação cursor-based"
```

**O que acontece por baixo:**
1. `architect` → analisa o requisito, define abordagem, identifica decisões
2. `api-designer` → projeta endpoint REST com OpenAPI (GET /api/v1/orders?status=CREATED&from=2025-01-01&cursor=xxx)
3. `dba` → projeta query, propõe índice composto, cria migration Flyway
4. `backend-dev` → implementa controller → use case → repository (hexagonal)
5. `code-reviewer` → revisa qualidade, segurança, padrões

**Resultado:** Feature completa com código, migration, e review — pronta para testes.

### Depois: gerar testes

```
> /qa-generate SearchOrdersUseCase
```

Gera:
- Teste unitário do use case (mockando o port out)
- Teste de integração do repository (Testcontainers + PostgreSQL real)
- Fixtures com Object Mother pattern

### Depois: review final

```
> /dev-review src/main/java/com/example/order/
```

## 2.2 Feature simples (só endpoint)

```
> /dev-api health-check
```

Projeta endpoint com OpenAPI spec — útil para endpoints simples que não precisam de todo o fluxo.

## 2.3 Feature com Kafka

```
> /dev-feature "publicar evento OrderCreated via Kafka quando pedido for criado, usando Outbox Pattern"
```

O `backend-dev` sabe criar:
- Outbox table (migration Flyway)
- Outbox publisher (polling ou CDC)
- Kafka producer com correlation ID e schema versionado
- Consumer idempotente com DLQ

## 2.4 Feature com cache Redis

```
> /dev-feature "adicionar cache Redis no endpoint de consulta de produto com TTL de 5 minutos e invalidação ao atualizar"
```

O `backend-dev` implementa:
- Cache-aside strategy
- TTL por tipo de dado
- Namespace: `{service}:{entity}:{id}`
- Stampede protection
- Fallback para DB se Redis indisponível

## 2.5 Feature multi-tenant

```
> /dev-feature "adicionar suporte multi-tenant com discriminador tenant_id em todas as queries"
```

Para Java 25+, usa `ScopedValue` no filter. Para Java 8/21, usa `ThreadLocal`.

---

# PARTE 3 — REFATORAÇÃO E CÓDIGO LEGADO

## 3.1 Refatorar classe complexa

```
> /dev-refactor OrderService
```

O `refactoring-engineer` analisa:
1. Complexidade ciclomática
2. Violações SOLID
3. Propõe plano de refatoração incremental
4. Executa em passos (cada um com testes passando)
5. `code-reviewer` valida que comportamento foi preservado

## 3.2 Extrair domain logic de um controller fat

```
> Use o refactoring-engineer para extrair a lógica de negócio do OrderController para a camada de domain
```

## 3.3 Migrar de Java 8 para 21

```
> preciso migrar este projeto de Java 8 + Spring Boot 2.7 para Java 21 + Spring Boot 3
```

Marcus identifica o cenário e sugere a sequência:
1. `architect` → avalia impacto, lista breaking changes (javax→jakarta)
2. `backend-dev` → executa migração incremental (detecta Java 8 no pom.xml, adapta)
3. `dba` → verifica compatibilidade Flyway
4. `/qa-audit` → valida que testes continuam passando

**Referência:** skill `application-development/java` tem o Migration Cheat Sheet completo.

## 3.4 Projeto Java 8 sem migração (manutenção)

```
> preciso corrigir o bug #456 no módulo de billing
```

Marcus detecta Java 8 no pom.xml. O `backend-dev` adapta automaticamente:
- Usa classes em vez de records
- Usa Optional sem pattern matching
- Usa ExecutorService em vez de virtual threads
- Sem text blocks, sem sealed classes

## 3.5 Reduzir dívida técnica

```
> Use o architect para mapear a dívida técnica deste módulo e priorizar o que resolver primeiro
```

O `architect` analisa:
- God classes
- Acoplamento temporal
- Código duplicado
- Testes faltando em paths críticos
- Propõe ADR com priorização

---

# PARTE 4 — BANCO DE DADOS

## 4.1 Query lenta

```
> /data-optimize "SELECT o.*, c.name, p.status FROM orders o JOIN customers c ON o.customer_id = c.id JOIN payments p ON p.order_id = o.id WHERE o.created_at > '2025-01-01' AND o.status IN ('CREATED', 'PROCESSING') ORDER BY o.created_at DESC LIMIT 50"
```

O command:
1. Roda EXPLAIN ANALYZE
2. Identifica: sequential scan, join type, rows estimated vs actual
3. Propõe índice composto com justificativa
4. Gera migration: `V{n}__add_idx_orders_status_created.sql`
5. Usa `CREATE INDEX CONCURRENTLY` (zero lock em produção)

## 4.2 Migration segura (adicionar coluna)

```
> /data-migrate "adicionar coluna discount_percentage na tabela orders como DECIMAL(5,2) nullable com default null"
```

O `dba` + `database-engineer`:
1. Avalia impacto (lock time, tamanho da tabela)
2. Gera migration em 2 fases se necessário (expand → backfill → contract)
3. Validação pré e pós migration
4. Plano de rollback

## 4.3 Migration destrutiva (remover coluna)

```
> /data-migrate "remover coluna legacy_status da tabela orders (250M registros)"
```

O approach para tabela grande:
1. Fase 1: remover referências no código (deploy)
2. Fase 2: `ALTER TABLE ... DROP COLUMN` (migration separada)
3. Para MySQL com tabela enorme: `pt-osc` ou `gh-ost`

## 4.4 Modelar schema novo

```
> Use o dba para modelar o schema do contexto de Notificações com suporte a multi-channel (email, SMS, push) e templates
```

## 4.5 MySQL — problemas específicos

```
> /data-optimize "query lenta na tabela users com collation utf8mb3"
```

O `mysql-engineer` identifica:
- Charset mismatch (utf8 vs utf8mb4)
- Implicit collation conversion matando índices
- Propõe fix com migration segura

## 4.6 PostgreSQL — VACUUM e bloat

```
> Use o database-engineer para analisar bloat e VACUUM na tabela orders
```

Analisa `pg_stat_user_tables`, dead tuples, last vacuum, e propõe ação.

---

# PARTE 5 — TESTES E QUALIDADE

## 5.1 Auditoria completa de qualidade

```
> /qa-audit
```

O `qa-lead` orquestra uma auditoria completa:
- Cobertura por módulo
- Proporção da pirâmide (unit vs integration vs E2E)
- Paths críticos sem cobertura
- Quality gates (80% coverage, 0 critical Sonar)
- Score geral com recomendações priorizadas

## 5.2 Gerar testes para uma classe

```
> /qa-generate CreateOrderUseCase
```

Gera:
- Testes unitários (happy path + edge cases + error paths)
- Fixture com Object Mother
- `@DisplayName` descritivo
- Given-When-Then structure

## 5.3 Gerar teste de integração

```
> /qa-generate OrderRepository --integration
```

Gera:
- `BaseIntegrationTest` com Testcontainers (PostgreSQL + Kafka + Redis)
- Teste que valida Flyway migrations
- Teste de CRUD completo com cleanup

## 5.4 Contract tests (entre microsserviços)

```
> /qa-contract order-service
```

O `contract-test-engineer` cria:
- Consumer-driven contracts (Pact ou Spring Cloud Contract)
- Testes para API REST + eventos Kafka
- Configuração de CI (falha bloqueia deploy)

## 5.5 Performance test

```
> /qa-performance order-service
```

O `performance-engineer` cria:
- Script Gatling ou k6
- Cenários: load test (baseline), stress test (limite), soak test (estabilidade)
- Assertions: p99 < SLO, error rate < 0.1%
- Integração com CI

## 5.6 Flaky test

```
> /qa-flaky OrderRepositoryIntegrationTest
```

O `test-automation-engineer`:
1. Analisa o teste
2. Identifica causa: race condition, time-dependent, shared state, test order dependency
3. Propõe fix (Awaitility, cleanup, isolamento)
4. Valida com múltiplas execuções

## 5.7 Testes de segurança OWASP

```
> /qa-security order-service
```

O `security-test-engineer` testa:
- Injection (SQL, NoSQL, command)
- Auth bypass (sem token, expirado, outro user)
- IDOR (acesso cross-tenant alterando IDs)
- XSS (em outputs que renderizam)
- Security headers (CORS, CSP, HSTS)
- Gera testes automatizados para CI

## 5.8 Testes E2E

```
> /qa-e2e "fluxo completo: criar pedido → pagar → confirmar → enviar notificação"
```

## 5.9 Review de testes existentes

```
> /qa-review src/test/java/com/example/order/
```

Identifica:
- Testes que testam implementação em vez de comportamento
- Testes sem assertion (false green)
- Over-mocking (testando o mock)
- Gaps de cobertura em paths de erro

---

# PARTE 6 — INFRAESTRUTURA E DEVOPS

## 6.1 Provisionar infra para serviço novo

```
> /devops-provision order-service aws
```

Cria tudo:
- Terraform: VPC, EKS, RDS, ElastiCache, MSK
- Kubernetes: Deployment, Service, ConfigMap, HPA, PDB, ServiceAccount
- CI/CD: GitHub Actions pipeline completo
- Observability: ServiceMonitor, alertas, dashboard
- Security: NetworkPolicy, Pod Security Context

## 6.2 Pipeline CI/CD

```
> /devops-pipeline order-service
```

O `cicd-engineer` cria GitHub Actions com:
- Build → Test → Quality Gate → Security Scan → Image Build → Push → Deploy
- Caching (Maven, Docker layers)
- OIDC auth (sem credentials estáticas)
- Matrix build (Java 21 + 25)
- Quality gates (coverage, Sonar, Trivy)

## 6.3 Observabilidade completa

```
> /devops-observe order-service
```

O `observability-engineer` configura:
- Prometheus ServiceMonitor
- Grafana dashboard (RED metrics + JVM + dependencies)
- Alertas: error rate > 1%, p99 > SLO, restarts > 3
- SLO com SLOTH (99.9% availability)
- Trace-log correlation

## 6.4 Kubernetes troubleshooting

```
> Use o kubernetes-engineer para investigar CrashLoopBackOff no payment-service
```

O agent:
1. `kubectl describe pod` — events, conditions
2. `kubectl logs --previous` — crash logs
3. `kubectl top pods` — resource usage
4. Diagnostica: OOM, probe failure, config error, dependency down
5. Propõe fix

## 6.5 Arquitetura AWS

```
> /devops-cloud "preciso projetar a infra para um serviço de processamento de vídeo com upload S3, transcoding, e notificação"
```

O `aws-cloud-engineer`:
- Propõe arquitetura (S3 → SQS → ECS Fargate → S3 + SNS)
- Trade-offs: Lambda vs ECS, MediaConvert vs custom
- Estimativa de custo
- IAM policies
- Validação de segurança

## 6.6 Terraform

```
> Use o iac-engineer para criar módulo Terraform para o RDS Aurora cluster
```

Cria:
- Módulo com variables tipadas
- Multi-AZ, encryption at rest
- Parameter group customizado
- Backup, PITR, maintenance window
- Outputs documentados

## 6.7 GitOps com ArgoCD

```
> /devops-gitops order-service
```

O `gitops-engineer`:
- ArgoCD Application manifest
- AppProject com RBAC
- Sync policy (auto-sync + prune + self-heal)
- Argo Rollouts para canary deployment
- Image Updater para write-back automático

## 6.8 Service Mesh

```
> /devops-mesh order-service
```

O `service-mesh-engineer`:
- VirtualService + DestinationRule
- mTLS STRICT
- Circuit breaking + retries + timeouts
- AuthorizationPolicy
- Canary com traffic shifting

## 6.9 FinOps — otimizar custos

```
> /devops-finops
```

O `finops-engineer`:
- Custo por categoria e por serviço
- Rightsizing candidates (EC2, RDS)
- Waste (ELBs idle, EBS unattached)
- Savings Plans coverage
- Quick wins vs investimentos

**Referência:** playbook `cost-optimization.md`

## 6.10 Disaster Recovery

```
> /devops-dr order-service
```

O `sre-engineer` + `iac-engineer`:
- RTO/RPO definidos
- Backup strategy (RDS snapshots, S3 replication)
- Failover plan (Route53 health check, Aurora failover)
- Runbook de restore
- Checklist de DR drill

**Referência:** playbooks `dr-drill.md` e `dr-restore.md`

## 6.11 Auditoria de infraestrutura

```
> /devops-audit
```

Auditoria multi-dimensão:
- Segurança (IAM, NetworkPolicy, secrets, RBAC)
- Custo (rightsizing, waste)
- Resiliência (probes, PDB, HPA, multi-AZ)
- Compliance

---

# PARTE 7 — INCIDENTES E OPERAÇÕES

## 7.1 Incidente ativo — serviço fora do ar

```
> /devops-incident "order-service retornando 503, dashboards mostram spike de erro"
```

O `sre-engineer` guia:
1. **Classify:** SEV1-4 baseado em impacto
2. **Gather signals:** pods, events, logs, métricas, deploys recentes
3. **Stabilize:** rollback, scale up, feature flag, rate limit
4. **Communicate:** status updates com template
5. **RCA:** postmortem blameless com timeline

**Referência:** playbook `incident-response.md`

## 7.2 Rollback de deploy

```
> preciso fazer rollback do último deploy do payment-service
```

Marcus sugere o playbook `rollback-strategy.md` e delega para `sre-engineer`:
```bash
kubectl rollout undo deployment/payment-service -n production
# ou
helm rollback payment-service -n production
```

## 7.3 Secret vazado

```
> achei uma API key exposta no repositório, preciso rotacionar
```

Marcus sugere o playbook `secret-rotation.md`:
1. Gerar nova credential
2. Atualizar no Secrets Manager
3. Trigger restart dos pods
4. Revogar credential antiga
5. Verificar que nenhum serviço quebrou

## 7.4 Problema de rede

```
> pods do order-service não conseguem se conectar ao payment-service
```

Marcus delega para `kubernetes-engineer` e sugere playbook `network-troubleshooting.md`:
1. DNS resolution (`nslookup` de dentro do pod)
2. NetworkPolicy blocking
3. Service selector matching
4. Port/protocol mismatch

## 7.5 Deploy seguro em produção

Antes de deployar, use a sequência de hardening:

```
> /qa-audit
> /qa-security order-service
> /devops-audit
> /qa-performance order-service
```

**Referência:** playbook `k8s-deploy-safe.md`

---

# PARTE 8 — MIGRAÇÃO DE MONÓLITO

## 8.1 Discovery — entender o monólito

```
> /migration-discovery
```

O `domain-analyst` + `data-engineer` + `security-engineer` + `tech-lead`:
1. Mapeiam bounded contexts (Event Storming)
2. Identificam acoplamentos de dados
3. Mapeiam dependências entre módulos
4. Classificam contextos por valor de negócio vs complexidade
5. Propõem ordem de extração

## 8.2 Preparar extração

```
> /migration-prepare payment
```

O `backend-engineer` + `qa-engineer`:
1. Criam seams (interfaces nos boundaries)
2. Adicionam testes de baseline (comportamento atual)
3. Medem métricas de acoplamento

## 8.3 Extrair microsserviço

```
> /migration-extract payment
```

Todos os 7 agents da Migration Team:
1. `domain-analyst` → confirma bounded context
2. `backend-engineer` → extrai código via Strangler Fig
3. `data-engineer` → split de schema (CDC ou dual-write)
4. `platform-engineer` → routing (shadow traffic, canary)
5. `qa-engineer` → testes de paridade
6. `security-engineer` → auth per service
7. `tech-lead` → coordena e gera ADR

## 8.4 Provisionar infra do novo serviço

```
> /devops-provision payment-service aws
```

## 8.5 Validar contratos

```
> /qa-contract payment-service
```

Garante que o novo microsserviço mantém paridade com o monólito.

## 8.6 Descomissionar do monólito

```
> /migration-decommission payment
```

Remove o módulo do monólito depois que o microsserviço está estável.

---

# PARTE 9 — DESIGN E ARQUITETURA

## 9.1 Decisão arquitetural (ADR)

```
> Use o architect para avaliar se devemos usar CQRS no módulo de relatórios
```

O `architect` gera ADR com:
- Contexto do problema
- Opções avaliadas com prós/contras
- Decisão com justificativa
- Consequências

## 9.2 Design de API REST

```
> /dev-api orders
```

O `api-designer` projeta:
- Endpoints com verbos HTTP corretos
- Request/Response schemas
- Error responses com Problem Details (RFC 9457)
- Paginação cursor-based
- Versionamento (/api/v1/)
- OpenAPI spec completa

## 9.3 Avaliar trade-off

```
> Use o architect para avaliar: Saga Pattern (orquestração) vs Saga Pattern (coreografia) para o fluxo de checkout
```

## 9.4 Revisão de arquitetura

```
> Use o architect para revisar a arquitetura do módulo de pagamentos e identificar problemas
```

---

# PARTE 10 — PLUGINS E FERRAMENTAS EXTRAS

## 10.1 Brainstorming com superpowers

```
> /brainstorm "como melhorar a resiliência do sistema de checkout"
```

Sessão interativa com suporte visual — gera ideias, avalia viabilidade, prioriza.

## 10.2 Planejar com superpowers

```
> /write-plan "migração do sistema de billing de Spring Boot 2 para 3"
```

Gera plano estruturado com fases, dependências, riscos, estimativas.

```
> /execute-plan
```

Executa o plano passo a passo.

## 10.3 Test generation com Qodo

O plugin `qodo-skills` ativa automaticamente quando você trabalha com testes — gera regras de teste e resolve PRs com testes.

## 10.4 Frontend com plugin

O plugin `frontend-design` ativa quando há trabalho de UI — React, componentes, layout.

## 10.5 Browser testing com Playwright

O plugin `playwright` ativa para automação de browser — testes E2E visuais, screenshots.

## 10.6 Episodic Memory — memória de longo prazo

O plugin `episodic-memory` dá ao Claude recall perfeito de tudo que você trabalhou em sessões anteriores.

**Instalação (uma vez):**
```bash
/plugin marketplace add obra/superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
```

**Uso automático — Claude busca sozinho quando relevante:**
```
> como resolvi aquele bug de connection pool na semana passada?
# Claude busca automaticamente nas conversas arquivadas via vector search
# e encontra a sessão onde você debugou o HikariCP timeout
```

**Uso explícito — forçar busca:**
```
> busque na memória episódica: "migração de schema orders"
# Retorna sessões relevantes com contexto
```

**O que é indexado:**
- Todas as conversas anteriores (arquivadas automaticamente via hook)
- Tool calls e resultados
- Decisões tomadas e justificativas
- Código gerado e bugs resolvidos

**Como funciona por baixo:**
```
SessionStart hook → arquiva conversas em ~/.config/superpowers/conversations-archive
SQLite + vector search → indexa semanticamente
MCP server → Claude busca via tool call
Haiku subagent → gerencia context bloat das buscas
Skill passiva → ensina Claude quando e como buscar
```

**Combinação com agent memory:**
- `memory:` no frontmatter = memória curada pelo agent (patterns, decisões)
- episodic-memory = recall bruto de tudo que aconteceu (conversas, tool calls)
- Juntos = agent lembra O QUE decidiu (memory) E POR QUÊ decidiu (episodic)

## 10.7 Criar agent personalizado

```
> /new-sdk-app
```

Scaffold de agent com Claude Agent SDK (Python ou TypeScript). Depois, verificar:

```
> Use o agent-sdk-dev:agent-sdk-verifier-py para verificar o agent Python
> Use o agent-sdk-dev:agent-sdk-verifier-ts para verificar o agent TypeScript
```

## 10.7 Code review avançado (plugin)

```
> /code-review
```

Review automatizado com o plugin. Alternativa do ecossistema:

```
> /dev-review src/
```

## 10.8 Instalar novo plugin

```
> /plugin                    # abre o plugin manager
> /plugin marketplace add davepoon/buildwithclaude   # 489+ plugins
> /plugin install {name}@{marketplace}
```

---

# PARTE 11 — CONNECTORS (MCP)

## 11.1 Conectar a ferramentas externas

Marcus sabe quais connectors estão disponíveis:

```
> quais connectors tenho disponíveis pra Slack?
```

Connectors se configuram em https://claude.com/connectors ou Settings → Connectors.

## 11.2 Integrar com GitHub

Connector GitHub permite que Claude acesse repos, issues, PRs diretamente.

## 11.3 Integrar com Jira/Asana

Para gestão de projeto — buscar tasks, atualizar status.

## 11.4 Custom MCP server

Para ferramentas internas, configure um remote MCP server URL (planos pagos).

---

# PARTE 12 — GESTÃO DO ECOSSISTEMA

## 12.1 Gerenciar skills

```bash
# Listar todas
~/.claude/skills/skill-helper.sh list

# Ver conteúdo
~/.claude/skills/skill-helper.sh show java

# Buscar keyword
~/.claude/skills/skill-helper.sh search kafka

# Validar
~/.claude/skills/skill-helper.sh validate java

# Criar nova skill
~/.claude/skills/skill-helper.sh new application-development/kafka
```

## 12.2 Criar agent personalizado

Crie um arquivo `.md` com YAML frontmatter em `~/.claude/agents/`:

```yaml
---
name: my-custom-agent
description: "Meu agent especializado em X"
tools: Read, Write, Edit, Bash, Glob, Grep
model: inherit
---

Instruções do agent aqui...
```

## 12.3 Criar slash command personalizado

Crie em `~/.claude/commands/`:

```yaml
---
name: my-command
description: "Meu command customizado"
argument-hint: "[argumento]"
---

Instruções de orquestração aqui...
Use o sub-agente **agent-name** para...
```

## 12.4 Atualizar ecossistema

```bash
# Baixar nova versão
unzip dot-claude-ready.zip
cd claude-home
./install.sh    # faz backup automático antes de sobrescrever
```

## 12.5 Entender a arquitetura

Para detalhes completos sobre como agents funcionam internamente — context isolation, tokens, memória, sandboxing — leia o **[ANEXO II — Arquitetura](ANEXOII-ANEXOII-ARQUITETURA.md)**.

Destaques rápidos:
- Cada subagent roda em **200K tokens isolados** — não polui Marcus
- 13 agents têm **memória persistente** entre sessões (aprendem)
- 16 agents têm **context: fork** (isolamento garantido)
- Agents read-only **não podem editar** seus arquivos

```bash
# Ver memória de um agent
cat ~/.claude/agent-memory/architect/MEMORY.md

# Pedir que consulte memória
> Use o architect para revisar. Consulte sua memória primeiro.

# Resetar memória
rm -rf ~/.claude/agent-memory/architect/
```

## 12.6 Diagnóstico

```
> /doctor                   # diagnóstico da instalação Claude Code
> /cost                     # custo de tokens da sessão
> /compact                  # comprimir histórico (liberar contexto)
> /memory                   # editar memória persistente
```

---

# PARTE 13 — FLUXOS COMPOSTOS (DIA A DIA)

## 13.1 Feature Sprint (segunda a sexta)

**Segunda — planejamento:**
```
> /brainstorm "features da sprint 15"
> /write-plan "implementação das 3 features priorizadas"
```

**Terça a quinta — implementação:**
```
> /dev-feature "feature 1: endpoint de webhook"
> /qa-generate WebhookUseCase
> /dev-feature "feature 2: filtro por data"
> /qa-generate FilterOrdersUseCase
> /dev-feature "feature 3: cache de produtos"
> /qa-generate ProductCacheUseCase
```

**Sexta — hardening:**
```
> /qa-audit
> /qa-security order-service
> /dev-review src/main/java/com/example/
> /devops-audit
```

## 13.2 Novo Microsserviço (ciclo completo em 1 dia)

```
# Manhã — estrutura e código
> /full-bootstrap notification-service aws

# Tarde — primeira feature real
> /dev-feature "implementar envio de notificação por email via SES"
> /qa-generate SendEmailNotificationUseCase

# Final do dia — pipeline e deploy staging
> /devops-pipeline notification-service
> /devops-gitops notification-service
```

## 13.3 Hardening Pré-Release

```
> /qa-audit                          # cobertura, pirâmide, gaps
> /qa-security order-service         # OWASP Top 10
> /qa-performance order-service      # load + stress test
> /devops-audit                      # segurança + custo + resiliência
> /qa-contract order-service         # contratos entre serviços
```

## 13.4 Onboarding de Dev Novo

```
# Explicar o projeto
> me explique a arquitetura e os padrões deste projeto

# Mostrar o que está disponível
> quais agents e commands eu tenho?

# Primeira task guiada
> /dev-feature "adicionar endpoint de health check detalhado"
```

## 13.5 Investigação de Bug

```
# 1. Entender o problema
> o endpoint GET /api/v1/orders/123 retorna 500 quando o pedido tem mais de 50 items

# Marcus analisa e sugere:
> Use o backend-dev para investigar o bug no endpoint de orders

# 2. Após identificar — fix + testes
> /qa-generate OrderDetailUseCase    # gerar teste que reproduz o bug
> /dev-review src/main/java/com/example/order/  # review do fix
```

## 13.6 Dependency Update Seguro

```
> preciso atualizar o Spring Boot de 3.2 para 3.4
```

Marcus sugere playbook `dependency-update.md`:
1. Branch dedicada
2. Atualizar `spring-boot-starter-parent`
3. Rodar tests: `./mvnw test`
4. Verificar breaking changes
5. `/qa-audit` para garantir nada quebrou
6. `/devops-pipeline` rebuild completo

## 13.7 Otimização de Tokens no Dia a Dia

```bash
# Cada agent já tem modelo otimizado por perfil:
#   Haiku (4 agents) → análise, auditoria, custo
#   Sonnet (31 agents) → implementação, testes, configs
#   Opus (2 agents) → arquitetura, decisões estratégicas
# Marcus roda em Sonnet e recomenda override quando faz sentido

claude --agent marcus                  # default — modelo por agent

# Opus só para arquitetura complexa
/model opus
> Use o architect para avaliar CQRS vs Event Sourcing
/model sonnet  # voltar ao default

# Comprimir a cada 30-45 min
/compact

# Limpar ao trocar de tarefa
/rename "feature-jwt"
/clear

# Ver custo da sessão
/cost
```

**Regras de ouro:**
1. Prompt específico > prompt vago (10x mais barato)
2. `/compact` a cada 30-45 min (evita contexto inflado)
3. Subagent > exploração direta (150K → 500 tokens no seu contexto)
4. Batch > múltiplas mensagens (1 inference em vez de 5)

Detalhes completos em **[ANEXO II — Arquitetura](ANEXOII-ANEXOII-ARQUITETURA.md)**.

## 13.8 Pair Programming com Marcus

```
# Marcus como par de programação
> estou pensando em usar CompletableFuture para paralelizar as chamadas ao payment-service e shipping-service, faz sentido?

# Marcus opina e sugere:
# Para Java 21: virtual threads com executor
# Para Java 25: StructuredTaskScope (melhor — cancela automaticamente)
# Referencia a skill java e delega para o backend-dev implementar
```

---


---

# PARTE 15 — GERAÇÃO DE PROMPTS E ARTEFATOS

## 15.1 Gerar prompt otimizado para um agent

Quando você sabe QUAL agent quer usar mas quer um prompt formulado da melhor forma:

```
> /gen-prompt prompt "backend-dev implementar autenticação JWT com refresh token, RBAC baseado em roles, e integração com Spring Security"
```

O `prompt-engineer` gera:
```
Use o backend-dev para implementar autenticação JWT com refresh token.

Contexto:
- Projeto: Java 21 / Spring Boot 3.2
- Banco: PostgreSQL
- Padrões: hexagonal architecture

Requisitos:
1. JWT access token (15min TTL) + refresh token (7 dias, rotativo)
2. RBAC com roles ADMIN, USER, VIEWER nas rotas REST
3. Spring Security filter chain com JwtAuthenticationFilter
4. Endpoint POST /api/v1/auth/login e POST /api/v1/auth/refresh
5. Blacklist de refresh tokens revogados (Redis ou tabela)

Output esperado:
- SecurityConfig.java com filter chain
- JwtService.java (geração, validação, refresh)
- AuthController.java com login e refresh
- Migration Flyway para tabela users + roles
- Testes unitários do JwtService
- Teste de integração do fluxo completo

Constraints:
- Problem Details (RFC 9457) para erros de auth
- Testcontainers para teste de integração, não H2
- Given-When-Then nos testes
- Secrets via environment variables, nunca hardcoded
```

## 15.2 Gerar prompt para tarefa complexa

```
> /gen-prompt prompt "architect avaliar se devemos usar Event Sourcing no módulo de pedidos"
```

## 15.3 Criar um agent novo

```
> /gen-prompt agent "especialista em Apache Kafka: producers com Outbox Pattern, consumers idempotentes com DLQ, schema registry com Avro, consumer groups, partition strategy, monitoring com lag alerts"
```

O `prompt-engineer` gera o arquivo `.md` completo com YAML frontmatter, pronto para salvar em `~/.claude/agents/kafka-engineer.md`.

## 15.4 Criar uma skill nova

```
> /gen-prompt skill "Redis caching: cache-aside, write-through, TTL strategies, stampede protection, eviction policies, cluster mode, Sentinel, connection pooling"
```

Gera `~/.claude/skills/cloud-infrastructure/redis/CLAUDE.md` com as 5 seções obrigatórias.

## 15.5 Criar um command novo

```
> /gen-prompt command "chaos engineering: orquestrar sre-engineer + kubernetes-engineer para injetar falhas controladas e validar resiliência"
```

Gera `/devops-chaos` command que orquestra agents em sequência.

## 15.6 Criar um playbook novo

```
> /gen-prompt playbook "canary deployment com Argo Rollouts: weight progression 5% → 25% → 50% → 100% com analysis template e rollback automático"
```

## 15.7 Otimizar CLAUDE.md de projeto

```
> /gen-prompt claudemd
```

O `prompt-engineer` analisa o projeto atual e gera um CLAUDE.md otimizado, alinhado com o global e referenciando agents/skills/commands relevantes.

## 15.8 Pedir recomendação de modelo

```
> /gen-prompt prompt "qual modelo e effort level devo usar para refatorar o módulo de pagamentos inteiro?"
```

O `prompt-engineer` analisa e responde:

```
Recomendação de execução:
  Modelo: opusplan (Opus planeja, Sonnet implementa)
  Effort: high
  Modo: /dev-refactor PaymentService
  Custo estimado: ~$2-4
  
  Para iniciar:
  claude --model opusplan --agent marcus
  /dev-refactor PaymentService
```

Outros exemplos rápidos:
```
> qual modelo pra fix simples de bug?     → sonnet, effort low, ~$0.10
> qual modelo pra arquitetura nova?       → opus, effort high, ~$1-3
> qual modelo pra explorar codebase?      → haiku, effort low, ~$0.05
> qual modelo pra /full-bootstrap?        → opusplan, effort high, ~$3-8
```

## 15.9 Otimizar um prompt que não funcionou bem

```
> /gen-prompt prompt "otimize este prompt que não deu bom resultado: 'faz autenticação no projeto'"
```

O `prompt-engineer` reescreve com:
- Especificidade (qual tipo de auth, qual framework, quais requisitos)
- Contexto do projeto
- Output esperado
- Constraints




---

# PARTE 16 — WORKFLOW DO MARCUS (5 FASES)

O Marcus v10 opera com um workflow estruturado de 5 fases. Entender o fluxo ajuda a tirar o máximo dele.

## 16.1 Fase 1: Triagem + Brainstorm

Quando você faz um pedido, Marcus:
1. Busca na **episodic memory**: "já resolvemos algo parecido?"
2. Se o pedido é **ambíguo**, pergunta UMA coisa antes de prosseguir
3. Classifica: **direta** (executa rápido) ou **complexa** (abre brainstorm)

Para tarefas complexas, Marcus abre brainstorm colaborativo:
```
User: quero criar um sistema de billing recorrente

Marcus (visão): Billing recorrente, desacoplado do monólito, retry automático.
Architect (técnico): Saga Pattern para consistência, Kafka para eventos,
  webhook para gateway. Risco: idempotência nos retries.
```

## 16.2 Fase 2: Plan

O agent especialista estrutura o plano:
```
Etapa 1: /dev-bootstrap billing-service
Etapa 2: /dev-feature "cobrança recorrente com Saga"
Etapa 3: /dev-feature "integração com gateway"
Etapa 4: /qa-generate + /qa-contract
Etapa 5: /devops-provision billing-service aws
```

O **prompt-engineer** traduz cada etapa em prompt otimizado. Fork de memória consolida contexto.

## 16.3 Fase 3: Aprovação + Salvar Plano

Marcus apresenta o plano e aguarda sua validação:
```
Marcus: Plano para billing-service:
  1. /dev-bootstrap → estrutura hexagonal
  2. /dev-feature → Saga Pattern + Kafka
  3. /dev-feature → gateway webhook
  4. /qa-generate + /qa-contract → testes
  5. /devops-provision → infra AWS

  Custo estimado: ~$8-12
  Risco: idempotência nos retries

  Aprova? Quer ajustar?
```

Após aprovação, o plano é **salvo automaticamente** em `.claude/plans/`:
```bash
cat .claude/plans/2026-03-19-billing-service.md
# Status: APROVADO
# Etapas: 5
# Riscos: idempotência nos retries
```

## 16.4 Fase 4: Execução

Agents executam na sequência. Marcus monitora e atualiza o plano:
```
1. ✅ /dev-bootstrap billing-service → CONCLUÍDO
2. 🔄 /dev-feature "Saga Pattern" → EM EXECUÇÃO
3. ⏳ /dev-feature "gateway" → PENDENTE
4. ⏳ /qa-generate → PENDENTE
5. ⏳ /devops-provision → PENDENTE
```

## 16.5 Fase 5: Pós-execução

Marcus valida o output contra o plano, sugere próximo passo e atualiza memória:
```
Marcus: Billing-service completo! ✅
  Todas as 5 etapas concluídas.

  Próximos passos:
  1. /qa-security billing-service (testes OWASP)
  2. /devops-observe billing-service (dashboards)

  Quer executar algum?
```

## 16.6 Retomar plano interrompido

Se a sessão cair no meio da execução:
```
> tenho um plano pendente de billing-service

Marcus: [lê .claude/plans/2026-03-19-billing-service.md]
Encontrei! Plano com 5 etapas, 2 concluídas, 3 pendentes.
Retomo da etapa 3? (/dev-feature "gateway webhook")
```

## 16.7 Listar planos

```bash
ls .claude/plans/
# 2026-03-19-billing-service.md
# 2026-03-15-notification-service.md
# 2026-03-10-migration-payment.md
```

# PARTE 14 — REFERÊNCIA RÁPIDA

## Cheat Sheet — "O que usar quando"

| Situação | Comando / Agent |
|----------|----------------|
| Feature nova | `/dev-feature "descrição"` |
| Serviço do zero | `/full-bootstrap nome aws` |
| Serviço do zero (só estrutura) | `/dev-bootstrap nome` |
| Code review | `/dev-review caminho/` |
| Refatorar | `/dev-refactor Classe` |
| Design API | `/dev-api recurso` |
| Gerar testes | `/qa-generate Classe` |
| Auditoria de qualidade | `/qa-audit` |
| Testes de segurança | `/qa-security serviço` |
| Load test | `/qa-performance serviço` |
| Contract test | `/qa-contract serviço` |
| E2E test | `/qa-e2e "fluxo"` |
| Flaky test | `/qa-flaky TestClass` |
| Query lenta | `/data-optimize "SELECT ..."` |
| Migration SQL | `/data-migrate "descrição"` |
| Infra completa | `/devops-provision serviço aws` |
| Pipeline CI/CD | `/devops-pipeline serviço` |
| Observabilidade | `/devops-observe serviço` |
| Incidente | `/devops-incident "descrição"` |
| Auditoria infra | `/devops-audit` |
| DR plan | `/devops-dr serviço` |
| Custos cloud | `/devops-finops` |
| GitOps | `/devops-gitops serviço` |
| Arquitetura AWS | `/devops-cloud serviço` |
| Service mesh | `/devops-mesh serviço` |
| Mapear monólito | `/migration-discovery` |
| Preparar extração | `/migration-prepare módulo` |
| Extrair microsserviço | `/migration-extract módulo` |
| Descomissionar legado | `/migration-decommission módulo` |
| Brainstorming | `/brainstorm "tema"` |
| Planejar | `/write-plan "descrição"` |
| Executar plano | `/execute-plan` |
| Code review (plugin) | `/code-review` |
| Agent SDK scaffold | `/new-sdk-app` |
| Gerar prompt/agent/skill | `/gen-prompt tipo "descrição"` |

## Cheat Sheet — "Qual playbook usar"

| Situação | Playbook |
|----------|----------|
| Serviço caiu | `incident-response.md` |
| Deploy deu errado | `rollback-strategy.md` |
| Alterar schema grande | `database-migration.md` |
| Secret vazou | `secret-rotation.md` |
| Auditoria segurança | `security-audit.md` |
| Terraform em prod | `terraform-plan-apply.md` |
| Deploy K8s | `k8s-deploy-safe.md` |
| Reduzir custos | `cost-optimization.md` |
| Simular DR | `dr-drill.md` |
| Restore real | `dr-restore.md` |
| Update deps | `dependency-update.md` |
| Debug rede | `network-troubleshooting.md` |

## Cheat Sheet — Comandos nativos essenciais

| Comando | Quando |
|---------|--------|
| `/compact` | Sessão longa, contexto cheio |
| `/clear` | Recomeçar limpo |
| `/cost` | Ver quanto gastou |
| `/agents` | Listar agents |
| `/plugin` | Gerenciar plugins |
| `/doctor` | Algo quebrado na instalação |
| `/init` | Projeto sem CLAUDE.md |
| `/memory` | Claude lembrar algo entre sessões |
| `--model opusplan` | Opus planeja + Sonnet implementa |
| `--model haiku` | Sessão barata (exploração) |
| `/effort low` | Menos thinking tokens |

---

**Ecossistema completo. 37 agents. 31 commands. 28 skills. 13 playbooks. 7 plugins.**

**Sempre comece com:** `claude --agent marcus`
