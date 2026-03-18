# 🏗️ Monolith Migration Agents — Claude Code

Equipe de sub-agentes especializados para decompor monólitos Java/Spring Boot em microsserviços usando Claude Code CLI.

## O Que É

Um conjunto de **7 sub-agentes** + **4 slash commands** + **1 CLAUDE.md** que transformam o Claude Code em uma equipe completa de migração:

| Agente | Cor | Especialidade |
|--------|-----|---------------|
| **Tech Lead** | 🔵 Azul | Coordenação, ADRs, priorização |
| **Domain Analyst** | 🟣 Roxo | Bounded contexts, Event Storming |
| **Backend Engineer** | 🟢 Verde | Implementação, refatoração, extração |
| **Data Engineer** | 🟡 Amarelo | Migração de dados, split de banco |
| **Platform Engineer** | 🔵 Cyan | Kubernetes, CI/CD, observabilidade |
| **QA Engineer** | 🟠 Laranja | Testes de paridade, contrato, chaos |
| **Security Engineer** | 🔴 Vermelho | Auth, compliance, auditoria |

## Instalação

### Opção A: Copiar para o projeto (recomendado)

```bash
# Na raiz do seu monólito
cp -r monolith-migration-agents/.claude .claude/
cp monolith-migration-agents/CLAUDE.md CLAUDE.md
mkdir -p docs/migration/{adr,context-maps,extraction-cards,runbooks,baselines}
```

### Opção B: Instalar globalmente

```bash
# Disponível em todos os projetos
cp monolith-migration-agents/.claude/agents/* ~/.claude/agents/
cp monolith-migration-agents/.claude/commands/* ~/.claude/commands/
```

## Como Usar

### Fluxo completo de migração

```
Fase 0 → Fase 1 → Fase 2 → Fase 3 → Fase 4 → Fase 5
                            ↑         |
                            └─────────┘
                          (repete por contexto)
```

### 1. Discovery do monólito (Fase 0)

```
claude> /migration-discovery
```

Orquestra Domain Analyst + Data Engineer + Security Engineer + Tech Lead para:
- Mapear bounded contexts, dependências, dados, segurança
- Gerar ranking de extração priorizado
- Gerar ADR-000

### 2. Preparar monólito (Fase 2)

```
claude> /migration-prepare order
```

Orquestra Backend Engineer + QA Engineer para:
- Criar seams e interfaces nos limites do contexto
- Capturar golden dataset e baseline de performance
- Configurar feature flags

### 3. Extrair microsserviço (Fase 3)

```
claude> /migration-extract order
```

Orquestra todos os agentes para:
- Implementar microsserviço hexagonal
- Planejar migração de dados
- Criar infra (Docker, Helm, CI/CD)
- Criar testes (unitários, integração, contrato, paridade)
- Revisar segurança
- Gerar ADR + runbook

### 4. Decommission (Fase 5)

```
claude> /migration-decommission order
```

Orquestra Backend Engineer + Data Engineer + QA para:
- Remover módulo do monólito
- Dropar tabelas (com backup)
- Validar regressão

### Uso direto de agentes

Além dos slash commands, você pode invocar agentes diretamente:

```
claude> Use o domain-analyst para mapear dependências entre Order e Payment
claude> Use o data-engineer para inventariar as tabelas do módulo Customer
claude> Use o backend-engineer para criar seams no módulo Inventory
claude> Use o qa-engineer para definir contract tests do payment-service
claude> Use o security-engineer para auditar o order-service
claude> Use o tech-lead para criar ADR sobre estratégia de CDC vs dual-write
```

### Iniciar sessão com agente específico

```bash
# Sessão inteira como Backend Engineer
claude --agent backend-engineer

# Sessão inteira como Tech Lead
claude --agent tech-lead
```

## Estrutura de Arquivos

```
.claude/
  agents/
    tech-lead.md            → Coordenação e decisão
    domain-analyst.md       → Modelagem e decomposição
    backend-engineer.md     → Implementação e extração
    data-engineer.md        → Dados e migração
    platform-engineer.md    → Infra e operação
    qa-engineer.md          → Qualidade e validação
    security-engineer.md    → Segurança e compliance
  commands/
    migration-discovery.md  → /migration-discovery (Fase 0)
    migration-prepare.md    → /migration-prepare (Fase 2)
    migration-extract.md    → /migration-extract (Fase 3)
    migration-decommission.md → /migration-decommission (Fase 5)

CLAUDE.md                   → Contexto do projeto, princípios, convenções

docs/migration/             → Artefatos gerados pela equipe
  adr/                      → Architecture Decision Records
  context-maps/             → Mapas de bounded contexts e dados
  extraction-cards/         → Fichas de extração por contexto
  runbooks/                 → Runbooks operacionais
  baselines/                → Golden datasets e baselines
```

## Princípios da Migração

1. **Strangler Fig** — monólito continua rodando. Nunca big bang.
2. **Incremental e reversível** — cada passo tem rollback.
3. **Paridade funcional primeiro** — replica antes de evoluir.
4. **Dados por último** — código e roteamento antes de mover dados.
5. **Coexistência prolongada** — projetado para monólito + microsserviços juntos.
6. **Teste comparativo** — paridade validada antes de promover.
7. **Observabilidade desde o dia zero** — métricas antes de tráfego.

## Stack

- Java 21+, Spring Boot 3.x
- PostgreSQL, Redis, Kafka
- Docker, Kubernetes, Helm
- Testcontainers, Flyway
- Prometheus, Grafana
- Spring Cloud Contract / Pact

## Integracao com Dev/QA/DevOps Teams

O Migration pack funciona standalone, mas para uma migracao completa recomenda-se combinar com os outros packs:

```
MIGRATION TEAM              DEV TEAM                QA TEAM                DEVOPS TEAM
---------------             ---------               --------               ------------
/migration-discovery
/migration-prepare   ->     /dev-refactor    ->     /qa-generate
/migration-extract   ->     /dev-bootstrap   ->     /qa-contract    ->     /devops-provision
                            /dev-feature     ->     /qa-audit       ->     /devops-pipeline
/migration-decommission                             /qa-e2e         ->     /devops-observe
```

Para combinar todos os packs:
```bash
cp -r teams-agents-monolith-migration/.claude/agents/* .claude/agents/
cp -r teams-agents-monolith-migration/.claude/commands/* .claude/commands/
cp -r teams-agents-dev/.claude/agents/* .claude/agents/
cp -r teams-agents-dev/.claude/commands/* .claude/commands/
cp -r teams-agents-qa/.claude/agents/* .claude/agents/
cp -r teams-agents-qa/.claude/commands/* .claude/commands/
cp -r teams-agents-devops/.claude/agents/* .claude/agents/
cp -r teams-agents-devops/.claude/commands/* .claude/commands/
```

**Resultado: 30 agentes + 20 slash commands** — equipe completa de migracao + engenharia.

## Customização

### Adicionar um agente

Crie um arquivo `.md` em `.claude/agents/` com frontmatter YAML:

```markdown
---
name: meu-agente
description: "Quando usar este agente..."
tools: Read, Write, Grep, Glob, Bash
model: inherit
color: green
---

# Instruções do agente aqui
```

### Adicionar um slash command

Crie um arquivo `.md` em `.claude/commands/`:

```markdown
---
name: meu-comando
description: "O que este comando faz"
argument-hint: "[argumentos]"
---

# Instruções para o Claude executar
```

### Usar interativamente

```
claude> /agents
```

Abre o gerenciador de agentes para criar, editar ou visualizar agentes.
