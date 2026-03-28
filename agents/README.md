# Claude Code Agents v10.2.0

**37 agentes especializados** organizados em **5 times** + **1 orquestrador global**.
**31 slash commands** para orquestração automática.
**4 workflows YAML** para execução estruturada com paralelismo e quality gates.

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
# 1. Descompactar e executar o instalador
unzip dot-claude-ready.zip && cd claude-home
chmod +x install.sh && ./install.sh

# 2. Pronto!
claude --agent marcus
```

## Os Times

### Dev Team — 6 agentes, 6 commands

Desenvolvimento backend Java 8/21/25+ / Spring Boot com arquitetura hexagonal.

| Comando | O que faz |
|---------|-----------|
| `/dev-feature "desc"` | Feature completa: design → API → schema → código → review |
| `/dev-bootstrap nome` | Novo microsserviço com estrutura hexagonal |
| `/full-bootstrap nome cloud` | **Cross-pack:** código + testes + infra + pipeline |
| `/dev-review path/` | Code review multi-perspectiva |
| `/dev-refactor Classe` | Refatoração segura |
| `/dev-api recurso` | Design de API REST com OpenAPI |

### QA Team — 8 agentes, 8 commands

Estratégia e automação de testes: unitários, integração, contrato, E2E, performance, segurança.

| Comando | O que faz |
|---------|-----------|
| `/qa-audit` | Auditoria completa de qualidade |
| `/qa-generate Classe` | Gerar testes unitários + integração |
| `/qa-review Classe` | Revisar testes, encontrar gaps |
| `/qa-performance serviço` | Load/stress/soak tests (Gatling/k6) |
| `/qa-flaky TestClass` | Diagnosticar e corrigir flaky tests |
| `/qa-contract serviço` | Contract tests REST + Kafka |
| `/qa-security serviço` | Testes OWASP |
| `/qa-e2e fluxo` | Testes E2E e smoke tests |

### DevOps Team — 11 agentes, 10 commands

Infraestrutura, CI/CD, GitOps, observabilidade, segurança ops, SRE e FinOps.

| Comando | O que faz |
|---------|-----------|
| `/devops-provision svc cloud` | Infra completa: IaC + K8s + CI/CD + observability |
| `/devops-pipeline serviço` | Pipeline CI/CD com quality gates |
| `/devops-observe serviço` | Observabilidade completa |
| `/devops-incident "desc"` | Gestão de incidente + postmortem |
| `/devops-audit` | Auditoria de infra |
| `/devops-dr serviço` | Disaster recovery |
| `/devops-finops` | Otimização de custos cloud |
| `/devops-gitops serviço` | ArgoCD / GitOps |
| `/devops-cloud serviço` | Arquitetura AWS |
| `/devops-mesh serviço` | Service mesh (Istio/Linkerd) |

### Data Team — 3 agentes, 2 commands

PostgreSQL, MySQL, schema design, migrations e performance tuning.

| Comando | O que faz |
|---------|-----------|
| `/data-optimize "query"` | Query lenta, índices, EXPLAIN ANALYZE |
| `/data-migrate "desc"` | Migrations SQL com zero-downtime |

### Migration Team — 7 agentes, 4 commands

Monólito → microsserviços via Strangler Fig Pattern.

| Comando | O que faz |
|---------|-----------|
| `/migration-discovery` | Mapear monólito, bounded contexts |
| `/migration-prepare módulo` | Criar seams e interfaces |
| `/migration-extract módulo` | Extrair como microsserviço |
| `/migration-decommission módulo` | Desativar no monólito |

### Utility — 1 agente, 1 command

| Comando | O que faz |
|---------|-----------|
| `/gen-prompt tipo "desc"` | Gerar prompts, agents, skills, commands, playbooks |

## Workflows (4)

Templates YAML em `~/.claude/workflows/` para execução estruturada na Fase 4 do Marcus:

| Workflow | Quando | Steps |
|----------|--------|-------|
| `feature-implementation` | Feature end-to-end | 7 (design → API+schema → implement → review+test) |
| `service-bootstrap` | Microsserviço do zero | 11 (Dev → QA → DevOps com infra paralela) |
| `infrastructure-provision` | Provisionar infra | 6 (IaC → K8s → CI/CD+Obs+Sec paralelo) |
| `migration-extract` | Strangler Fig extraction | 8 (analysis → implement+data → infra → test+sec) |

Ver `~/.claude/workflows/README.md` para schema YAML completo.

## Checks (7)

Micro-checklists de quality gates em `~/.claude/checks/`:

| Check | Valida |
|-------|--------|
| `probes-defined.md` | Liveness + readiness probes configuradas |
| `resource-limits.md` | Requests/limits definidos |
| `terraform-fmt.md` | Formatação Terraform |
| `terraform-validate.md` | Validação Terraform |
| `tests-pass.md` | Testes passando |
| `no-critical-review-findings.md` | Sem achados críticos no review |
| `contract-tests-defined.md` | Contract tests definidos |

## Playbooks (13)

Guias operacionais passo-a-passo em `~/.claude/playbooks/`. Marcus os sugere quando o contexto pede.

## Plugins (7)

| Plugin | O que adiciona |
|--------|---------------|
| **superpowers** | `/brainstorm`, `/write-plan`, `/execute-plan` + skills TDD, debugging, code-review |
| **agent-sdk-dev** | `/new-sdk-app` + verificadores Python/TS |
| **code-review** | `/code-review` automatizado |
| **frontend-design** | Skill passiva para frontend/UI |
| **playwright** | Skill passiva para automação de browser |
| **qodo-skills** | Skills passivas para regras de teste e PR |
| **episodic-memory** | Memória semântica de longo prazo |

## Validação

```bash
# Completa
~/.claude/validate-ecosystem.sh

# Detalhada
~/.claude/validate-ecosystem.sh --verbose

# Por seção
~/.claude/validate-ecosystem.sh --section agents
~/.claude/validate-ecosystem.sh --section workflows

# Auto-fix (remove junk files)
~/.claude/validate-ecosystem.sh --fix
```

## Totais

| Componente | Quantidade |
|------------|-----------|
| Agents | 37 |
| Commands (pack) | 31 |
| Commands (plugin) | 5 |
| Skills | 28 |
| Workflows | 4 |
| Playbooks | 13 |
| Checks | 7 |
| Plugins | 7 |
