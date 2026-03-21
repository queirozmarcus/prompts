# 🧪 QA Team — Claude Code Agents

Equipe de sub-agentes de QA especializados para projetos Java/Spring Boot. Cobre unitários, integração, contrato, performance, E2E, segurança e automação.

## A Equipe

| Agente | Cor | Especialidade |
|--------|-----|---------------|
| **QA Lead** | 🔵 | Estratégia, planejamento, quality gates, priorização |
| **Unit Test Engineer** | 🟢 | Testes unitários, TDD, mocking, domain logic |
| **Integration Test Engineer** | 🟡 | Testcontainers, Spring Boot Test, Kafka, Redis |
| **Contract Test Engineer** | 🟣 | Pact, Spring Cloud Contract, schema validation |
| **Performance Engineer** | 🟠 | Gatling, k6, load/stress/soak tests |
| **E2E Test Engineer** | 🔵 Cyan | RestAssured, Playwright, API flows, smoke tests |
| **Test Automation Engineer** | 🩷 | Geração de testes, flaky detection, mutation testing |
| **Security Test Engineer** | 🔴 | OWASP, auth bypass, IDOR, dependency scan |

## Instalação

```bash
# Na raiz do seu projeto Java/Spring Boot
cp -r qa-team-agents/.claude/agents/* .claude/agents/
cp -r qa-team-agents/.claude/commands/* .claude/commands/
cp qa-team-agents/CLAUDE.md CLAUDE.md  # ou merge com CLAUDE.md existente
mkdir -p docs/qa/{strategies,reports,contracts,runbooks}
```

Para instalar globalmente (disponível em todos os projetos):
```bash
cp -r qa-team-agents/.claude/agents/* ~/.claude/agents/
cp -r qa-team-agents/.claude/commands/* ~/.claude/commands/
```

## Slash Commands

### `/qa-audit` — Auditoria completa
```
claude> /qa-audit
```
Orquestra QA Lead + Test Automation Engineer + Security Test Engineer para análise completa: cobertura, pirâmide, segurança, velocidade, score de qualidade.

### `/qa-generate` — Gerar testes
```
claude> /qa-generate CreateOrderUseCase
claude> /qa-generate com.example.order.domain.model
claude> /qa-generate src/main/java/com/example/order/application/
```
Analisa o código e gera testes unitários + integração completos.

### `/qa-review` — Revisar testes existentes
```
claude> /qa-review CreateOrderUseCaseTest
claude> /qa-review src/test/java/com/example/order/
```
Revisa qualidade dos testes, identifica gaps, anti-patterns e melhorias.

### `/qa-performance` — Testes de performance
```
claude> /qa-performance order-service
claude> /qa-performance checkout-flow
```
Cria scripts Gatling/k6 com cenários de load, stress e soak.

### `/qa-flaky` — Diagnosticar flaky tests
```
claude> /qa-flaky OrderRepositoryIntegrationTest
```
Investiga causa raiz, corrige e previne recorrencia.

### `/qa-contract` — Contract tests
```
claude> /qa-contract order-service
claude> /qa-contract payment-api
```
Cria/valida contract tests REST e Kafka para um servico.

### `/qa-e2e` — Testes end-to-end
```
claude> /qa-e2e order-payment-flow
claude> /qa-e2e checkout-flow
```
Cria testes E2E, smoke tests e testes de API para fluxos completos.

## Uso Direto de Agentes

```
claude> Use o unit-test-engineer para gerar testes do DiscountCalculator
claude> Use o contract-test-engineer para definir o contrato da API de Orders
claude> Use o performance-engineer para analisar estes resultados de load test
claude> Use o security-test-engineer para testar OWASP Top 10 na API
claude> Use o test-automation-engineer para reproduzir o bug BUG-1234
claude> Use o integration-test-engineer para criar teste do Kafka consumer
claude> Use o e2e-test-engineer para criar smoke tests pós-deploy
```

## Sessão Dedicada com Agente

```bash
# Sessão inteira como Unit Test Engineer
claude --agent unit-test-engineer

# Sessão inteira como Performance Engineer
claude --agent performance-engineer
```

## Estrutura de Arquivos

```
.claude/
  agents/
    qa-lead.md                    → Estratégia e governança
    unit-test-engineer.md         → Testes unitários e TDD
    integration-test-engineer.md  → Testcontainers e infra real
    contract-test-engineer.md     → Contratos REST e Kafka
    performance-engineer.md       → Load, stress, soak tests
    e2e-test-engineer.md          → API testing e smoke tests
    test-automation-engineer.md   → Geração, flaky, mutation
    security-test-engineer.md     → Segurança e OWASP
  commands/
    qa-audit.md                   → /qa-audit
    qa-generate.md                → /qa-generate
    qa-review.md                  → /qa-review
    qa-performance.md             → /qa-performance
    qa-flaky.md                   → /qa-flaky

CLAUDE.md                         → Contexto, convenções, quality gates

docs/qa/
  strategies/     → Estratégias de teste por módulo
  reports/        → Relatórios de audit, cobertura, performance
  contracts/      → Contratos versionados (REST, Kafka)
  runbooks/       → Guias de troubleshooting
```

## Quality Gates Padrão

```
Unitários:      >80% cobertura em domain + application, 0 falhas
Integração:     Fluxos críticos cobertos, 0 falhas
Contrato:       100% compliance, bloqueia deploy se falhar
Performance:    p99 < SLO, zero regressão vs baseline
E2E:            Happy paths + error paths críticos
Segurança:      0 vulnerabilidades critical/high
Sonar:          0 critical, 0 blocker, debt ratio < 5%
Mutation:       >80% mutation score em domain + application
```

## Pirâmide de Testes Ideal

```
         /  E2E  \         ~10% — fluxos críticos de negócio
        /----------\
       / Contrato   \      ~5%  — APIs e eventos entre serviços
      /--------------\
     /  Integração    \    ~20% — infra real com Testcontainers
    /------------------\
   /    Unitários       \  ~65% — domain model, use cases, lógica
  /______________________\
```

## Integracao com Dev Team

Este pack e complementar ao **Dev Team** (`teams-agents-dev`). O fluxo recomendado:

```
DEV TEAM                     QA TEAM
---------                    --------
/dev-feature  -> implementa  ->  /qa-generate  -> gera testes
/dev-refactor -> refatora    ->  /qa-review    -> valida testes
/dev-bootstrap -> novo servico -> /qa-audit    -> audita qualidade
/dev-api      -> define API  ->  /qa-contract  -> testa contratos
                                 /qa-e2e       -> testa fluxos E2E
```

Para combinar ambos:
```bash
cp -r teams-agents-dev/.claude/agents/* .claude/agents/
cp -r teams-agents-dev/.claude/commands/* .claude/commands/
cp -r teams-agents-qa/.claude/agents/* .claude/agents/
cp -r teams-agents-qa/.claude/commands/* .claude/commands/
```

## Compatibilidade

Este pack funciona standalone em qualquer projeto Java/Spring Boot, ou combinado com outros packs:

```bash
# Combinar com Dev + DevOps (equipe completa de engenharia)
cp -r teams-agents-dev/.claude/agents/* .claude/agents/
cp -r teams-agents-dev/.claude/commands/* .claude/commands/
cp -r teams-agents-qa/.claude/agents/* .claude/agents/
cp -r teams-agents-qa/.claude/commands/* .claude/commands/
cp -r teams-agents-devops/.claude/agents/* .claude/agents/
cp -r teams-agents-devops/.claude/commands/* .claude/commands/
```

Os agentes de QA complementam os agentes de migracao — use `/qa-generate` para gerar testes de um microsservico recem-extraido, `/qa-audit` para auditar qualidade antes de ir para producao.
