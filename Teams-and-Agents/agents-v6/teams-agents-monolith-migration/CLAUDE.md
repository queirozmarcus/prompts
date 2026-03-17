# Monolith-to-Microservices Migration Project

## Visão Geral

Este projeto utiliza uma equipe de sub-agentes especializados no Claude Code para decompor monólitos Java/Spring Boot em microsserviços de forma incremental, segura e reversível.

## Estratégia de Migração: Strangler Fig

Toda migração segue o padrão Strangler Fig — o monólito continua rodando enquanto microsserviços assumem responsabilidades incrementalmente. Nunca big bang.

## Princípios Inegociáveis

1. **Incremental e reversível** — cada extração é um passo isolado com rollback imediato
2. **Paridade funcional primeiro** — microsserviço replica comportamento antes de evoluir
3. **Dados por último** — extraia código e roteamento antes de migrar dados
4. **Coexistência prolongada** — monólito e microsserviços coexistem em produção
5. **Teste comparativo** — toda extração inclui validação de paridade (shadow traffic, parallel run, contract tests)
6. **Observabilidade desde o dia zero** — métricas, logs, traces e alertas antes de rotear tráfego

## Sub-Agentes Disponíveis

| Agente | Arquivo | Quando Usar |
|--------|---------|-------------|
| Tech Lead | `.claude/agents/tech-lead.md` | Coordenação, priorização, ADRs, decisões arquiteturais |
| Domain Analyst | `.claude/agents/domain-analyst.md` | Event Storming, bounded contexts, context mapping |
| Backend Engineer | `.claude/agents/backend-engineer.md` | Implementação, refatoração, extração de código |
| Data Engineer | `.claude/agents/data-engineer.md` | Migração de dados, split de banco, CDC, integridade |
| Platform Engineer | `.claude/agents/platform-engineer.md` | Kubernetes, CI/CD, observabilidade, infraestrutura |
| QA Engineer | `.claude/agents/qa-engineer.md` | Testes de paridade, contrato, carga, regressão, chaos |
| Security Engineer | `.claude/agents/security-engineer.md` | Auth, permissões, compliance, auditoria |

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/migration-discovery` | Fase 0: Análise completa do monólito |
| `/migration-extract` | Fase 3: Extrair bounded context como microsserviço |

## Fases da Migração

```
Fase 0: Discovery → Fase 1: Decomposição → Fase 2: Preparação → Fase 3: Extração → Fase 4: Operação → Fase 5: Decommission
```

A Fase 3 se repete para cada bounded context extraído.

## Convenções

- Pacotes: `com.{org}.{serviço}.{domain|application|adapter.in|adapter.out|config}`
- Serviços: `{domínio}-service` (ex: `order-service`)
- Tópicos Kafka: `{domínio}.{entidade}.{ação}.v{n}`
- Migrations: `V{n}__{descricao}.sql`
- Feature flags: `ff.migration.{contexto}.{capability}`
- Endpoints: `/api/v{n}/{recurso}` (kebab-case, plural)

## Stack

Java 21+, Spring Boot 3.x, PostgreSQL, Redis, Kafka, Docker, Kubernetes, Testcontainers, Flyway.

## Artefatos da Migração

Todos os artefatos de discovery, ADRs e runbooks ficam em `docs/migration/`:

```
docs/migration/
  adr/              → Architecture Decision Records
  context-maps/     → Mapas de bounded contexts
  extraction-cards/ → Fichas de extração por contexto
  runbooks/         → Runbooks operacionais por serviço
  baselines/        → Baselines de comportamento e performance
```
