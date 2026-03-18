# QA Team — Claude Code Agents

## Visão Geral

Equipe de sub-agentes de QA especializados para projetos Java/Spring Boot. Cada agente é um especialista que opera no seu próprio context window com ferramentas e instruções focadas.

## A Equipe

| Agente | Especialidade | Quando Usar |
|--------|---------------|-------------|
| **QA Lead** | Estratégia, planejamento, priorização, quality gates | Definir abordagem, revisar cobertura, planejar sprints de teste |
| **Unit Test Engineer** | Testes unitários, TDD, mocking, domain logic | Gerar/revisar testes de unidade, cobertura de regras de negócio |
| **Integration Test Engineer** | Testcontainers, Spring Boot Test, repositórios, Kafka, Redis | Testar integrações reais com infra via containers |
| **Contract Test Engineer** | Pact, Spring Cloud Contract, schema validation | Contratos REST, Kafka, integrações entre serviços |
| **Performance Engineer** | Gatling, k6, JMeter, profiling, bottleneck analysis | Load test, stress test, soak test, tuning |
| **E2E Test Engineer** | RestAssured, Selenium, Playwright, API flows | Fluxos end-to-end, API testing, regressão funcional |
| **Test Automation Engineer** | Geração de testes, flaky detection, bug reproduction | Gerar testes a partir de código, diagnosticar flaky, reproduzir bugs |
| **Security Test Engineer** | OWASP, fuzzing, auth bypass, injection, dependency scan | Pen testing automatizado, validação de segurança |

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/qa-audit` | Auditoria completa de qualidade do projeto |
| `/qa-generate` | Gerar testes para um módulo ou classe |
| `/qa-review` | Revisar testes existentes e identificar gaps |
| `/qa-performance` | Planejar e criar testes de performance |
| `/qa-flaky` | Diagnosticar e corrigir testes instáveis |
| `/qa-contract` | Criar/validar contract tests para um serviço |
| `/qa-e2e` | Criar testes end-to-end para um fluxo |

## Convenções de Teste

### Nomenclatura
- Unitários: `{Classe}Test` → `CreateOrderUseCaseTest`
- Integração: `{Classe}IntegrationTest` → `OrderRepositoryIntegrationTest`
- Contrato: `{Serviço}ContractTest` → `OrderApiContractTest`
- Performance: `{Fluxo}PerfTest` → `OrderCreationPerfTest`
- E2E: `{Fluxo}E2ETest` → `OrderPaymentFlowE2ETest`
- Segurança: `{Alvo}SecurityTest` → `OrderApiSecurityTest`

### Estrutura de pacotes de teste
```
src/test/java/com/{org}/{serviço}/
  unit/                → Testes unitários (domain, use cases)
  integration/         → Testcontainers (persistence, messaging, cache)
  contract/            → Contract tests (REST, Kafka)
  e2e/                 → End-to-end (fluxos completos)
  performance/         → Gatling/k6 scripts
  security/            → Security tests
  fixture/             → Builders, factories, mothers, fixtures compartilhados
```

### Quality Gates
```
Unitários:    >80% cobertura em domain + application, 0 falhas
Integração:   Fluxos críticos cobertos, 0 falhas
Contrato:     100% compliance, bloqueia deploy se falhar
Performance:  Latência p99 < SLO, zero regressão vs baseline
E2E:          Happy paths + error paths críticos
Segurança:    0 vulnerabilidades critical/high
Sonar:        0 critical, 0 blocker, debt ratio < 5%
```

## Stack de Teste

- JUnit 5, AssertJ, Mockito
- Testcontainers (PostgreSQL, Kafka, Redis)
- Spring Boot Test, MockMvc, WebTestClient
- RestAssured
- Spring Cloud Contract / Pact
- Gatling / k6
- Playwright / Selenium (quando houver frontend)
- ArchUnit
- Pitest (mutation testing)
- OWASP ZAP, Trivy, Snyk

## Artefatos

```
docs/qa/
  strategies/   → Estratégias de teste por módulo/serviço
  reports/      → Relatórios de cobertura, performance, segurança
  contracts/    → Contratos versionados (REST, Kafka)
  runbooks/     → Guias de troubleshooting de testes
```
