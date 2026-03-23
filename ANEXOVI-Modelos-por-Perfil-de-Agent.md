# ANEXOVI — Modelos por Perfil de Agent

**Versão:** v10.2.0
**Última atualização:** 2026-03-23
**Escopo:** Estratégia de atribuição de modelos Claude (haiku, sonnet, opus) aos 37 agentes do ecossistema Marcus.

---

## Introdução

Cada agente do ecossistema foi atribuído a um modelo Claude baseado no seu perfil de trabalho:
- **Análise** → Haiku (barato, rápido)
- **Implementação** → Sonnet (equilíbrio custo-qualidade)
- **Arquitetura/Estratégia** → Opus (raciocínio profundo, trade-offs)

Este anexo documenta a estratégia completa, justificativas, e quando fazer override.

---

## Estratégia Global

### Distribuição por Perfil

| Perfil | Modelo | Custo Relativo | Quantidade | Uso Típico |
|--------|--------|---|---|---|
| **Analysis** | `haiku` | 1x (barato) | 4 agents | Classificação, apreciação de risco, métricas |
| **Implementation** | `sonnet` | 4x | 31 agents | Geração de código, templates, padrões aplicados |
| **Architecture** | `opus` | 20x (premium) | 2 agents | Design, trade-offs, ADRs, estratégia |
| **Routing** | `sonnet` | 4x | 1 (Marcus) | Orquestração (não implementa, mas precisa entender contexto) |

### Resumo Executivo

```
Total de Agents: 37

Distribuição por Modelo:
  ✅ Haiku:   4 agents (11%)  — Analysts
  ✅ Sonnet: 31 agents (84%)  — Implementers
  ✅ Opus:    2 agents (5%)   — Architects
```

---

## Modelos por Time

### Dev Team — 6 Agentes

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **architect** | **opus** | Design de sistemas, trade-offs entre sync/async, SAGA vs Outbox, CQRS, Event Sourcing. Exige raciocínio arquitetural profundo e avaliação de múltiplas perspectivas. |
| **backend-dev** | **sonnet** | Implementação hexagonal (8 passos bem definidos), domain model, adapters. Detecta Java 8/21/25+ e adapta features. Pattern-matching forte. |
| **api-designer** | **sonnet** | OpenAPI 3.1, paginação cursor, Problem Details, versionamento. Specifications claras, exemplo de schema bem definido. |
| **devops-engineer** | **sonnet** | Docker, K8s, Helm, CI/CD, Prometheus, docker-compose. Templates reproduzíveis, pouco trade-off. |
| **code-reviewer** | **sonnet** | Review de bugs, design, segurança, performance (N+1), padrões, complexidade. Análise de código existente, sem decisões arquiteturais. |
| **refactoring-engineer** | **sonnet** | Safe refactoring, SOLID, extract methods, dead code, pattern migration. Trabalho mecânico com suporte de testes. |

### QA Team — 8 Agentes

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **qa-lead** | **haiku** | Estratégia de testes, risco, quality gates, pirâmide de testes, métricas. Análise, não execução. |
| **unit-test-engineer** | **sonnet** | Testes unitários com TDD, edge cases, mocking, Pitest. Geração de código de teste. |
| **integration-test-engineer** | **sonnet** | Testcontainers (PostgreSQL, Kafka, Redis), repository tests, messaging, migration validation. Integração complexa. |
| **contract-test-engineer** | **sonnet** | Pact, Spring Cloud Contract, Kafka schema versionado, backward compatibility. Templates bem definidos. |
| **performance-engineer** | **sonnet** | Load/stress/soak/spike tests (Gatling, k6), baseline, bottleneck analysis. Análise + implementação. |
| **e2e-test-engineer** | **sonnet** | RestAssured, fluxos multi-step, smoke tests, cross-service. Testes claros com padrão BDD. |
| **test-automation-engineer** | **sonnet** | Flaky detection, coverage gaps, Pitest (mutation testing), suite optimization. Trabalho de análise + refactoring. |
| **security-test-engineer** | **sonnet** | OWASP Top 10, auth bypass, IDOR, fuzzing, CVE scanning (Trivy). Testes de segurança bem estruturados. |

### DevOps Team — 11 Agentes

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **devops-lead** | **haiku** | Estratégia de plataforma, FinOps, SLOs, capacity planning, governança. Análise pura. |
| **iac-engineer** | **sonnet** | Terraform modules, state management, multi-environment, IAM, encryption. Templates módulos com vars/outputs. |
| **cicd-engineer** | **sonnet** | GitHub Actions pipelines, GitOps, quality gates, canary/blue-green. Workflows e automação. |
| **kubernetes-engineer** | **sonnet** | Workloads (Deployment, StatefulSet, Jobs), HPA/VPA/Karpenter, networking, storage, probes, troubleshooting. Complexo mas com patterns claros. |
| **observability-engineer** | **sonnet** | Prometheus (scraping, rules, recording rules), Grafana dashboards, Loki, OpenTelemetry, alertas SLO. Templates + PromQL. |
| **security-ops** | **sonnet** | Vault, RBAC, NetworkPolicy, image scanning, CIS, LGPD, pod security standards, hardening. Configuração + decisão. |
| **service-mesh-engineer** | **sonnet** | Istio mTLS, canary, fault injection, L7 authorization, rate limiting. Templates de mesh com padrões. |
| **sre-engineer** | **sonnet** | Incidents, postmortems blameless, chaos engineering, DR (RTO/RPO), capacity, runbooks. Análise + decisão operacional. |
| **aws-cloud-engineer** | **sonnet** | EKS vs ECS, ALB/NLB, RDS/Aurora, VPC, IAM least-privilege, CloudWatch, multi-region. Arquitetura AWS aplicada. |
| **finops-engineer** | **haiku** | Análise de custo (Cost Explorer, CUR, Budgets), rightsizing, waste identification, Savings Plans vs Reserved Instances. Pura análise. |
| **gitops-engineer** | **sonnet** | ArgoCD Application/AppProject, Argo Rollouts, Helm, Kustomize, Image Updater, drift detection, sync policies. Templates e automação. |

### Data Team — 3 Agentes

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **dba** | **sonnet** | Schema design, Flyway migrations, indexação, EXPLAIN ANALYZE, JPA tuning, Outbox pattern. SQL complexity média. |
| **database-engineer** | **sonnet** | PostgreSQL tuning (VACUUM, bloat, replication), Aurora, PITR, cross-region replication, DR. Deep database ops. |
| **mysql-engineer** | **sonnet** | MySQL 8.x operations, pt-osc/gh-ost, GTID replication, charset fixes, performance tuning. Expertise MySQL. |

### Migration Team — 7 Agentes

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **tech-lead** | **opus** | Priorização de extração, matriz de acoplamento, ADRs de migração, trade-offs Strangler Fig. Coordenação estratégica. |
| **domain-analyst** | **haiku** | Event Storming, bounded contexts, context mapping, domain events, relationships. Análise de domínio. |
| **backend-engineer** | **sonnet** | Criação de seams, extração de contextos, paridade funcional, Outbox, Saga, Kafka + DLQ. Implementação complexa. |
| **data-engineer** | **sonnet** | Schema split, CDC, dual-write, ETL, data validation, FK resolution. Dados + implementação. |
| **platform-engineer** | **sonnet** | Shadow traffic, canary deployment, blue-green, feature toggles, coexistência monólito + microsserviços. Routing + deployment. |
| **qa-engineer** | **sonnet** | Testes de paridade funcional (golden dataset, parallel run), contract tests, regressão, carga, chaos. QA complexa. |
| **security-engineer** | **sonnet** | Auth distribuído, mTLS automático, RBAC, LGPD compliance, API hardening, auditoria. Segurança em contexto de migração. |

### Utility — 1 Agente

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **prompt-engineer** | **sonnet** | Gerar prompts, agents, skills, commands, playbooks, CLAUDE.md. Trabalho criativo + conhecimento de padrões. |

### Agent-Marcus — 1 Agente Especial

| Agent | Modelo | Justificativa |
|-------|--------|---------------|
| **marcus** | **sonnet** | Orquestrador global: classifica tarefas, roteia para agents, executa workflow. Não implementa, logo Sonnet basta. Conhece 36 commands + skills + plugins. |

---

## Quando Fazer Override de Modelo

Marcus recomenda override quando o contexto demandar mais (ou menos) poder computacional.

### Cenários de Override

#### 1. Tarefa Trivial com Agent Sonnet → Use `/effort low`

**Situação:** Rename simples, correção de typo, ajuste trivial.

**Override:**
```bash
claude --effort low --agent backend-dev
/dev-feature "renomear variável de 'x' para 'quantity'"
```

**Benefício:** Reduz tokens e custo, mantém qualidade.

---

#### 2. Tarefa Complexa com Agent Haiku → Use `--model sonnet`

**Situação:** FinOps precisa avaliar arquitetura multi-region com trade-offs de custo vs latência.

**Override:**
```bash
claude --model sonnet --agent finops-engineer
/devops-finops order-service
```

**Justificativa:** Haiku é suficiente para "custos de hoje", mas trade-offs futuros exigem Sonnet.

---

#### 3. Refactoring Grande → Use `--model opusplan`

**Situação:** Reescrever módulo inteiro (500+ linhas) com mudança arquitetural.

**Fluxo:**
```bash
# Fase 1: Opus planeja a refactoring
claude --model opusplan --agent marcus
/dev-refactor PaymentService

# Fase 2: Sonnet executa conforme plano
# (automático se usando opusplan)
```

**Resultado:** Opus define estratégia de refactoring → Sonnet implementa → reduz risco.

---

#### 4. Debug Complexo em Produção → Use `--model opus`

**Situação:** Bug que exige raciocínio multi-sistema (latência vem de N+1? Cache? Banco? Rede?).

**Override:**
```bash
claude --model opus --agent sre-engineer
/devops-incident "latência p99 de 5s no order-service, spike às 14:30"
```

**Justificativa:** SRE com Opus pode correlacionar logs, métricas, traces e identificar causa-raiz mais rápido.

---

#### 5. Exploração Arquitetural → Usa Opus Nativo

**Situação:** Avaliar viabilidade de CQRS, Event Sourcing, ou Service Mesh numa codebase existente.

**Uso:**
```bash
claude --agent architect
# architect já roda em Opus
```

**Sem override:** Architect já vem configurado em Opus, é o default.

---

## Model Strategy na Prática

### Exemplo 1: Feature Simples
```bash
# Feature: "adicionar filtro por data na listagem de pedidos"
# Expectativa: 2 controllers, 1 repository query, testes

claude --agent marcus
/dev-feature "adicionar filtro por data na listagem de pedidos"

# Marcus roteia:
# 1. architect (opus) — design 5 min (simples, template conhecido)
# 2. backend-dev (sonnet) — implementação 10 min
# 3. code-reviewer (sonnet) — review 5 min
# Custo total: baixo (1 Opus, 2 Sonnet)
```

### Exemplo 2: Refactoring de Módulo
```bash
# Tarefa: "refatorar OrderService, está com 500 linhas, complexidade muito alta"

claude --model opusplan --agent marcus

# opusplan = Opus planeja, depois Sonnet executa
# Resultado:
# - Opus: estratégia de decomposição (30 min)
# - Sonnet: implementação (60 min)
# Custo: 1 Opus plano + 1 Sonnet execução
```

### Exemplo 3: Incidente P1
```bash
# Incidente: "CPU em 95%, requests timeout, cascata de erros"

claude --model opus --agent sre-engineer
/devops-incident "CPU 95%, timeout cascata"

# Opus SRE correlaciona:
# - Prometheus metrics
# - Application logs
# - Traces distribuídos
# - Identifica: conexão DB não pooled, N+1 query
# Custo: 1 Opus (urgente, justificado)
```

### Exemplo 4: FinOps Planejamento
```bash
# Tarefa: "otimizar custos da infra AWS"

/devops-finops

# finops-engineer (haiku) analisa:
# - Current spend por serviço
# - Rightsizing recommendations
# - Savings Plans vs Reserved Instances
# - Resultado: plano de ação de 3 meses
# Custo: 1 Haiku (barato, valor alto)
```

---

## Guia de Decisão: Quando Recomendar Override

### Decision Tree

```
Tarefa é simples? (typo, rename, < 50 linhas)
  ├─ SIM → /effort low com Sonnet (economia)
  └─ NÃO → próximo

Tarefa exige decisão estratégica? (design, trade-offs, ADR)
  ├─ SIM → Opus (architect, tech-lead já defaults Opus)
  └─ NÃO → próximo

Tarefa é análise pura? (métricas, risco, classificação)
  ├─ SIM → Haiku suficiente (economia)
  └─ NÃO → próximo

Tarefa envolve raciocínio multi-contexto? (debug complexo, multi-sistema)
  ├─ SIM → --model opus (urgência justificada)
  └─ NÃO → Sonnet default

Tarefa é refactoring grande? (500+ linhas, mudança arquitetural)
  ├─ SIM → --model opusplan (Opus plano, Sonnet executa)
  └─ NÃO → Sonnet default
```

---

## Matriz Custo vs Complexidade

| Complexidade | Haiku | Sonnet | Opus | Recomendação |
|---|---|---|---|---|
| **Trivial** (rename, typo) | ✅ | ⚠️ | ❌ | Haiku ou `/effort low` |
| **Simples** (feature padrão) | ❌ | ✅ | ❌ | Sonnet |
| **Média** (integração, bug complexo) | ❌ | ✅ | ⚠️ | Sonnet; Opus se urgente |
| **Alta** (design, refactoring grande) | ❌ | ❌ | ✅ | Opus |
| **Análise pura** (métricas, risco) | ✅ | ⚠️ | ❌ | Haiku |
| **Estratégia** (planejamento migração) | ❌ | ❌ | ✅ | Opus |

---

## Referência Rápida por Agent

### Agents que SEMPRE devem usar modelo default (sem override)

| Agent | Modelo | Por quê |
|-------|--------|--------|
| `architect` | opus | Sempre design — não há "design trivial" |
| `tech-lead` | opus | Sempre estratégia |
| `qa-lead` | haiku | Análise de risco, sempre suficiente |
| `domain-analyst` | haiku | Análise de domínio, sempre suficiente |
| `devops-lead` | haiku | Análise de plataforma, sempre suficiente |
| `finops-engineer` | haiku | Análise de custo, sempre suficiente |

### Agents que podem ter override em casos específicos

| Agent | Default | Caso para Opus | Caso para Haiku |
|-------|---------|---|---|
| `backend-dev` | sonnet | Refactoring grande de módulo | Feature trivial com `/effort low` |
| `sre-engineer` | sonnet | Incidente P1 complexo | Runbook pré-existente |
| `security-ops` | sonnet | Auditoria pré-go-live | Validação de config conhecida |
| `database-engineer` | sonnet | Otimização de query crítica | Índice simples em tabela pequena |

---

## Custo Estimado por Tarefa Típica

### Exemplo: Feature Simples (Adicionar filtro)

```
architect (opus)      : 5 min × $0.015/min = $0.075
backend-dev (sonnet)  : 10 min × $0.003/min = $0.030
code-reviewer (sonnet): 5 min × $0.003/min = $0.015
────────────────────────────────────────────
Custo total: ~$0.12
```

### Exemplo: Incidente P1 (Debug complexo)

```
sre-engineer (opus)   : 20 min × $0.015/min = $0.300
Custo: ~$0.30 (justificado por urgência)
```

### Exemplo: Refactoring Grande (500 linhas)

```
architect (opus)      : 30 min × $0.015/min = $0.450
backend-dev (sonnet)  : 60 min × $0.003/min = $0.180
code-reviewer (sonnet): 15 min × $0.003/min = $0.045
────────────────────────────────────────────
Custo total: ~$0.675 (vs ~$1.50 com Opus puro)
```

---

## Notas Importantes

1. **Marcus sempre sabe:** Marcus é configurado com essa estratégia — ele recomenda override automaticamente quando detecta cenário que o justifica.

2. **Não é dogma:** Se você acha que uma tarefa precisa de Opus, use. Esta é uma estratégia, não uma lei. Marcus aconselha, usuário decide.

3. **Custo é consideração:** Opus é 20x mais caro que Sonnet. Para tarefas rotineiras, Sonnet é suficiente 99% do tempo.

4. **Qualidade > Custo (quando urgência):** Em produção (P1, segurança), use Opus sem hesitar. O custo da falha é maior.

5. **Skills + Agents:** Agents usam skills passivas para enriquecer contexto. Uma skill não muda o modelo do agent — é contexto adicional.

---

## Histórico de Mudanças

| Versão | Data | Mudança |
|--------|------|--------|
| v10.2.0 | 2026-03-23 | Documento criado com 37 agents e estratégia de modelos |
| v10.0.0 | 2026-02-14 | Estratégia de modelos definida (Haiku/Sonnet/Opus) |

---

## Ver Também

- **CLAUDE.md** (global) — Strategy model recommendations
- **ANEXOIV** — Agent Capabilities (capacidades detalhadas dos 37 agents)
- **ANEXOII** — Arquitetura (context window, tokens, memória)
- `marcus.md` — Definição do Agent-Marcus

