# Dev Team — Claude Code Agents

## Visão Geral

Equipe de sub-agentes de desenvolvimento backend para projetos Java 21+ / Spring Boot 3.x. Cobre arquitetura, implementação, APIs, infraestrutura e CI/CD.

**Integração com QA Team:** Use `/qa-generate` após implementar, `/qa-audit` antes de release.
**Integração com Data Team:** O DBA agora pertence ao Data pack (`teams-agents-data`). Use `/data-optimize` e `/data-migrate` para tarefas de banco.

## A Equipe

| Agente | Especialidade | Quando Usar |
|--------|---------------|-------------|
| **Architect** | Design, decisões, ADRs, trade-offs, módulos | Decisões estruturais, novos serviços, refatoração arquitetural |
| **Backend Engineer** | Implementação Java/Spring Boot, hexagonal, regras de negócio | Features, use cases, adapters, refatoração de código |
| **API Designer** | OpenAPI, contratos REST, versionamento, Problem Details | Projetar APIs, documentar, versionar, padronizar erros |
| **DevOps Engineer** | Docker, Kubernetes, Helm, CI/CD, observabilidade | Infra, pipelines, deploys, monitoring, alertas |
| **Code Reviewer** | Revisão de código, qualidade, padrões, segurança | PR reviews, refatoração, enforcement de padrões |
| **Refactoring Engineer** | Refatoração segura, redução de complexidade, clean code | Dívida técnica, simplificação, extração de módulos |

## Slash Commands

| Comando | Descrição |
|---------|-----------|
| `/dev-feature` | Implementar feature completa (API → use case → persistence) |
| `/dev-bootstrap` | Bootstrap de microsserviço novo (estrutura + infra + CI) |
| `/dev-review` | Code review completo com todos os agentes |
| `/dev-refactor` | Refatoração segura com preservação de comportamento |
| `/dev-api` | Projetar API REST completa com OpenAPI |
| `/full-bootstrap` | Bootstrap completo cross-pack: código + testes + infra + pipeline (Dev + QA + DevOps) |

## Convenções

### Arquitetura Hexagonal
```
src/main/java/com/{org}/{serviço}/
  domain/
    model/          → Entidades, Value Objects, Aggregates (ZERO dependência de framework)
    port/in/        → Interfaces de use cases (inbound)
    port/out/       → Interfaces de repositório, publisher, client (outbound)
    exception/      → Exceções de domínio (funcionais)
  application/
    usecase/        → Implementação dos use cases
    service/        → Orquestração, serviços de aplicação
  adapter/
    in/web/         → REST Controllers + DTOs
    in/messaging/   → Kafka Consumers
    out/persistence/→ JPA Repositories + Entities + Mappers
    out/messaging/  → Kafka Producers
    out/http/       → HTTP Clients para outros serviços
  config/           → Spring config, beans, security
infrastructure/
  exception/        → Global exception handler, Problem Details
```

### Nomenclatura
- Pacotes: `com.{org}.{serviço}.{camada}`
- Classes: `{Entidade}UseCase`, `{Entidade}Controller`, `{Entidade}JpaRepository`
- Endpoints: `/api/v{n}/{recurso}` (kebab-case, plural)
- Tópicos Kafka: `{domínio}.{entidade}.{ação}.v{n}`
- DTOs: `{Entidade}Request`, `{Entidade}Response`
- Eventos: `{Entidade}{Ação}Event`
- Migrations: `V{n}__{descricao}.sql`
- Exceções: `{Entidade}NotFoundException`, `{Regra}ViolationException`
- Códigos de erro: `{DOMÍNIO}-{NNN}` (ex: `ORDER-001`, `PAYMENT-003`)

### Stack
Java 21+, Spring Boot 3.x, PostgreSQL, Redis, Kafka, Docker, Kubernetes, Flyway, Testcontainers

### Padrões Técnicos Inegociáveis
- Arquitetura hexagonal (domínio sem dependência de framework)
- Problem Details (RFC 9457) para erros
- OpenAPI/Swagger para toda API
- Flyway para migrations
- Logs estruturados (JSON) com correlationId
- Health checks (liveness + readiness)
- Graceful shutdown
- Configuração externa (12-factor)
- Métricas Prometheus

## Artefatos

```
docs/
  architecture/
    adr/        → Architecture Decision Records
    diagrams/   → Diagramas (C4, sequência, etc)
  api/          → OpenAPI specs, contratos
  runbooks/     → Guias operacionais
```
