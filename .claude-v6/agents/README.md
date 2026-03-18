# Claude Code Agents v5

**36 agentes especializados** organizados em **5 times** + **1 orquestrador global**.
**27 slash commands** para orquestração automática.

## Como Funciona

```bash
# Sempre comece assim:
claude --agent marcus

# Marcus roteia tudo. Exemplos:
> preciso criar um serviço de notificações do zero
Marcus → /full-bootstrap notification-service aws

> query de listagem de pedidos está demorando 3s
Marcus → /data-optimize "SELECT ... FROM orders"

> o order-service está com latência alta
Marcus → /devops-incident "latência p99 alta no order-service"

> quero revisar o código do módulo de pagamentos
Marcus → /dev-review src/main/java/com/example/payment/
```

Você nunca precisa saber qual agente chamar. **Marcus classifica e delega.**

## Instalação

```bash
# 1. Instalar Marcus globalmente
cp marcus-agent.md ~/.claude/agents/marcus.md

# 2. Instalar todos os packs
for pack in teams-agents-dev teams-agents-qa teams-agents-devops teams-agents-data teams-agents-monolith-migration; do
  cp -r "$pack/.claude/agents/"* ~/.claude/agents/ 2>/dev/null
  mkdir -p ~/.claude/commands
  cp -r "$pack/.claude/commands/"* ~/.claude/commands/ 2>/dev/null
done

# 3. Pronto!
claude --agent marcus
```

## Os Times

### 🛠️ Dev Team — 6 agentes, 6 commands

Desenvolvimento backend Java 21+ / Spring Boot 3.x com arquitetura hexagonal.

| Comando | O que faz |
|---------|-----------|
| `/dev-feature "desc"` | Feature completa: design → API → schema → código → review |
| `/dev-bootstrap nome` | Novo microsserviço com estrutura hexagonal |
| `/full-bootstrap nome cloud` | **Cross-pack:** código + testes + infra + pipeline |
| `/dev-review path/` | Code review multi-perspectiva |
| `/dev-refactor Classe` | Refatoração segura |
| `/dev-api recurso` | Design de API REST com OpenAPI |

### 🧪 QA Team — 8 agentes, 7 commands

Estratégia e automação de testes: unitários, integração, contrato, E2E, performance, segurança.

| Comando | O que faz |
|---------|-----------|
| `/qa-audit` | Auditoria completa de qualidade |
| `/qa-generate Classe` | Gerar testes unitários + integração |
| `/qa-review Classe` | Revisar testes, encontrar gaps |
| `/qa-performance serviço` | Load/stress/soak tests (Gatling/k6) |
| `/qa-flaky TestClass` | Diagnosticar e corrigir flaky tests |
| `/qa-contract serviço` | Contract tests REST + Kafka |
| `/qa-e2e fluxo` | Testes E2E e smoke tests |

### ⚙️ DevOps Team — 11 agentes, 8 commands

Infraestrutura, CI/CD, GitOps, observabilidade, segurança ops, SRE e FinOps.

| Comando | O que faz |
|---------|-----------|
| `/devops-provision svc cloud` | Infra completa: IaC + K8s + CI/CD + observability |
| `/devops-pipeline svc` | Pipeline CI/CD com quality gates |
| `/devops-observe svc` | Prometheus + Grafana + Loki + alertas |
| `/devops-incident "desc"` | Resposta a incidente + postmortem |
| `/devops-audit` | Auditoria: segurança + custo + resiliência |
| `/devops-dr svc` | Disaster recovery planning |
| `/devops-finops` | Análise de custo e otimização |
| `/devops-gitops svc` | Setup ArgoCD/FluxCD |

### 🗄️ Data Team — 3 agentes, 2 commands

Banco de dados: PostgreSQL, MySQL/MariaDB, schema design, migrations, query optimization.

| Comando | O que faz |
|---------|-----------|
| `/data-optimize query` | EXPLAIN ANALYZE + indexação + migration |
| `/data-migrate "desc"` | Migration zero-downtime + rollback + validação |

### 🏗️ Migration Team — 7 agentes, 4 commands

Decomposição de monólitos via Strangler Fig.

| Comando | O que faz |
|---------|-----------|
| `/migration-discovery` | Análise completa do monólito |
| `/migration-prepare ctx` | Criar seams e capturar baseline |
| `/migration-extract ctx` | Extrair bounded context como microsserviço |
| `/migration-decommission ctx` | Remover módulo migrado |

## Fluxos Comuns

### Novo serviço (do zero até produção)
```
/full-bootstrap order-service aws
```
Um comando. Dev + QA + DevOps orquestrados.

### Feature → review → testes
```
/dev-feature "adicionar filtro por data nos pedidos"
/dev-review src/main/java/com/example/order/
/qa-generate FilterOrdersUseCase
```

### Hardening pré-release
```
/qa-audit
/devops-audit
/qa-performance order-service
```

### Problema em produção
```
/devops-incident "latência alta no order-service"
```

### Migração de monólito
```
/migration-discovery
/migration-prepare payment
/migration-extract payment
/qa-contract payment-service
/devops-provision payment-service aws
/migration-decommission payment
```

## Estrutura do Repositório

```
marcus-agent.md                          → Orquestrador global
validate-agents.sh                       → Script de validação

teams-agents-dev/                        → Dev Team (6 agents, 6 commands)
  .claude/agents/                        → architect, backend-dev, api-designer,
                                           devops-engineer, code-reviewer, refactoring-engineer
  .claude/commands/                      → dev-feature, dev-bootstrap, dev-review,
                                           dev-refactor, dev-api, full-bootstrap

teams-agents-qa/                         → QA Team (8 agents, 7 commands)
  .claude/agents/                        → qa-lead, unit-test-engineer, integration-test-engineer,
                                           contract-test-engineer, performance-engineer,
                                           e2e-test-engineer, test-automation-engineer,
                                           security-test-engineer
  .claude/commands/                      → qa-audit, qa-generate, qa-review, qa-performance,
                                           qa-flaky, qa-contract, qa-e2e

teams-agents-devops/                     → DevOps Team (11 agents, 8 commands)
  .claude/agents/                        → devops-lead, iac-engineer, cicd-engineer,
                                           kubernetes-engineer, observability-engineer,
                                           security-ops, service-mesh-engineer, sre-engineer,
                                           aws-cloud-engineer, finops-engineer, gitops-engineer
  .claude/commands/                      → devops-provision, devops-pipeline, devops-observe,
                                           devops-incident, devops-audit, devops-dr,
                                           devops-finops, devops-gitops

teams-agents-data/                       → Data Team (3 agents, 2 commands)
  .claude/agents/                        → dba, database-engineer, mysql-engineer
  .claude/commands/                      → data-optimize, data-migrate

teams-agents-monolith-migration/         → Migration Team (7 agents, 4 commands)
  .claude/agents/                        → tech-lead, domain-analyst, backend-engineer,
                                           data-engineer, platform-engineer, qa-engineer,
                                           security-engineer
  .claude/commands/                      → migration-discovery, migration-prepare,
                                           migration-extract, migration-decommission
```
