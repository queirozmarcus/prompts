# 🛠️ Dev Team — Claude Code Agents

Equipe de sub-agentes de desenvolvimento backend para projetos Java 21+ / Spring Boot 3.x. Cobre arquitetura, implementação, banco de dados, APIs, infraestrutura e CI/CD.

## A Equipe

| Agente | Cor | Especialidade |
|--------|-----|---------------|
| **Architect** | 🔵 | Design, ADRs, trade-offs, padrões distribuídos |
| **Backend Dev** | 🟢 | Implementação hexagonal, use cases, adapters |
| **API Designer** | 🟣 | OpenAPI, REST design, Problem Details, versionamento |
| **DBA** | 🟡 | Schema, migrations, queries, indexação, JPA tuning |
| **DevOps Engineer** | 🔵 Cyan | Docker, Kubernetes, Helm, CI/CD, observabilidade |
| **Code Reviewer** | 🟠 | Review de código, qualidade, segurança, padrões |
| **Refactoring Engineer** | 🩷 | Refatoração segura, clean code, redução de complexidade |

## Instalação

```bash
# Na raiz do seu projeto
cp -r dev-team-agents/.claude/agents/* .claude/agents/
cp -r dev-team-agents/.claude/commands/* .claude/commands/
cp dev-team-agents/CLAUDE.md CLAUDE.md  # ou merge com existente
mkdir -p docs/architecture/adr docs/architecture/diagrams docs/api docs/runbooks
```

Global:
```bash
cp -r dev-team-agents/.claude/agents/* ~/.claude/agents/
cp -r dev-team-agents/.claude/commands/* ~/.claude/commands/
```

## Slash Commands

### `/dev-bootstrap order` — Criar microsserviço novo
Gera estrutura hexagonal completa + Dockerfile + Helm + CI/CD + docker-compose + ADR.

### `/dev-feature "criar endpoint de cancelamento de pedido"` — Implementar feature
Fluxo completo: design → API → schema → implementação → code review.

### `/dev-review src/main/java/com/example/order/` — Code review
Review multi-perspectiva: código + arquitetura + banco.

### `/dev-refactor OrderService` — Refatoração segura
Análise → plano → execução incremental → review do resultado.

### `/dev-api orders` — Projetar API REST
Gera OpenAPI spec completa com endpoints, schemas, erros, paginação.

### `/full-bootstrap order-service aws` — Bootstrap completo (cross-pack)
Orquestra Dev + QA + DevOps em uma única execução: estrutura hexagonal + testes + Dockerfile + Helm + CI/CD + observabilidade + security. Requer que os 3 packs estejam instalados.

## Uso Direto de Agentes

```
claude> Use o architect para avaliar se precisamos de CQRS
claude> Use o backend-dev para implementar o use case CreateOrder
claude> Use o api-designer para revisar esta API e apontar problemas
claude> Use o dba para otimizar esta query lenta
claude> Use o devops-engineer para criar Helm chart do payment-service
claude> Use o code-reviewer para revisar o PR #42
claude> Use o refactoring-engineer para simplificar OrderService
```

## Sessão Dedicada

```bash
claude --agent backend-dev     # sessão de implementação
claude --agent architect       # sessão de design
claude --agent dba             # sessão de banco de dados
```

## Integração com QA Team

Este pack é **complementar ao QA Team** (`qa-team-agents`). O fluxo recomendado:

```
/dev-feature → implementa  →  /qa-generate → gera testes
/dev-refactor → refatora   →  /qa-review → valida testes
/dev-bootstrap → novo serviço → /qa-audit → audita qualidade
```

Para combinar ambos:
```bash
cp -r dev-team-agents/.claude/agents/* .claude/agents/
cp -r dev-team-agents/.claude/commands/* .claude/commands/
cp -r qa-team-agents/.claude/agents/* .claude/agents/
cp -r qa-team-agents/.claude/commands/* .claude/commands/
```

## Estrutura

```
.claude/
  agents/
    architect.md              → Design e decisões
    backend-dev.md            → Implementação Java/Spring Boot
    api-designer.md           → REST APIs e OpenAPI
    dba.md                    → Banco de dados e migrations
    devops-engineer.md        → Infra, Docker, K8s, CI/CD
    code-reviewer.md          → Revisão de código
    refactoring-engineer.md   → Refatoração segura
  commands/
    dev-feature.md            → /dev-feature
    dev-bootstrap.md          → /dev-bootstrap
    dev-review.md             → /dev-review
    dev-refactor.md           → /dev-refactor
    dev-api.md                → /dev-api
    full-bootstrap.md         → /full-bootstrap (cross-pack)

CLAUDE.md                     → Contexto, convenções, padrões

docs/
  architecture/adr/           → Architecture Decision Records
  architecture/diagrams/      → Diagramas C4, sequência
  api/                        → OpenAPI specs
  runbooks/                   → Guias operacionais
```
