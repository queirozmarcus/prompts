# Claude Code Agent Ecosystem

**37 agentes especializados** · **31 slash commands** · **28 skills passivas** · **12 playbooks operacionais**

Um ecossistema completo para desenvolvimento backend Java/Spring Boot, QA, DevOps/SRE, Data, e migração de monólitos — tudo orquestrado pelo **Agent-Marcus** no terminal.

```
┌─────────────────────────────────────────────────────────────┐
│                     Agent-Marcus (global)                     │
│       Orquestrador · Claude Code Expert · PT-BR · 🚀         │
├──────────┬──────────┬───────────┬────────┬──────────────────┤
│ Dev (6)  │ QA (8)   │ DevOps(11)│Data (3)│ Migration (7)    │
│ 6 cmds   │ 8 cmds   │ 11 cmds   │ 2 cmds │ 4 cmds          │
│          Utility: prompt-engineer (1 agent, 1 cmd)           │
└──────────┴──────────┴───────────┴────────┴──────────────────┘
```

---

## Instalação

### Pré-requisitos

- Claude Code CLI instalado (`npm install -g @anthropic-ai/claude-code`)
- Conta Claude (Pro, Max ou API key)

### Instalar o ecossistema

```bash
# 1. Descompactar
unzip dot-claude-ready.zip
cd claude-home

# 2. Executar o instalador (faz backup automático do ~/.claude existente)
chmod +x install.sh
./install.sh

# 3. Pronto!
claude --agent marcus
```

### Verificar instalação

```bash
# Agents instalados (deve mostrar 37)
ls ~/.claude/agents/*.md | wc -l

# Commands disponíveis (deve mostrar 31)
ls ~/.claude/commands/*.md | wc -l

# Skills instaladas (deve mostrar 28)
find ~/.claude/skills -name "CLAUDE.md" | wc -l

# Listar agents no Claude Code
claude agents
```

---

## Como Funciona

Você sempre começa com Marcus. Ele é seu ponto de entrada para tudo.

```bash
claude --agent marcus
```

Marcus faz uma varredura do projeto (tipo de projeto, infra, plugins instalados) e fica pronto para rotear qualquer pedido para o especialista certo. Você nunca precisa saber qual agent chamar — **descreva o que precisa e Marcus delega**.

### O Fluxo

```
Você descreve o problema
    ↓
Marcus classifica e roteia
    ↓
┌─────────────────────────────┐
│ Slash command (orquestra     │ ← para tarefas multi-step
│ múltiplos agents)            │
└──────────┬──────────────────┘
           │
┌──────────▼──────────────────┐
│ Agent especialista           │ ← executa com context isolado
│ (enriched por skill passiva) │
└─────────────────────────────┘
```

---

## Casos de Uso

### 1. "Preciso criar um microsserviço do zero"

O cenário mais completo — código, testes, infra, pipeline, observabilidade:

```
> /full-bootstrap notification-service aws
```

Marcus orquestra **3 packs em sequência**:
1. **Dev pack** → estrutura hexagonal, application.yml, use case placeholder, OpenAPI, Flyway
2. **QA pack** → testes unitários, integração com Testcontainers, quality gates
3. **DevOps pack** → Dockerfile multi-stage, Helm chart, pipeline CI/CD, Prometheus, alertas, NetworkPolicy

**Resultado:** microsserviço production-ready com uma execução.

Para mais controle (passo a passo):

```
> /dev-bootstrap notification-service
> /qa-audit
> /devops-provision notification-service aws
```

---

### 2. "Preciso implementar uma feature"

```
> /dev-feature "adicionar filtro por data e status nos pedidos com paginação"
```

O command orquestra a sequência completa:
1. `architect` → design da abordagem, decisões
2. `api-designer` → endpoint REST com OpenAPI
3. `dba` → migration Flyway para índice composto
4. `backend-dev` → implementação hexagonal (controller → use case → repository)
5. `code-reviewer` → review de qualidade

Depois, gere os testes:

```
> /qa-generate FilterOrdersUseCase
```

---

### 3. "Tenho uma query lenta"

```
> /data-optimize "SELECT o.*, c.name FROM orders o JOIN customers c ON o.customer_id = c.id WHERE o.status = 'CREATED' AND o.created_at > '2025-01-01'"
```

O command:
1. Roda `EXPLAIN ANALYZE`
2. Identifica: sequential scan, missing index, join cost
3. Propõe índice composto `(status, created_at)` com justificativa
4. Gera migration Flyway: `V{n}__add_idx_orders_status_created.sql` com `CREATE INDEX CONCURRENTLY`

---

### 4. "O serviço está fora do ar"

```
> /devops-incident "order-service indisponível, erro 503 intermitente"
```

O `sre-engineer` assume:
1. Signal gathering (pods, events, logs, métricas)
2. Identifica causa (OOMKilled, CrashLoopBackOff, dependency down)
3. Mitigação imediata (rollback, scale up, feature flag)
4. Status updates com template
5. Gera postmortem blameless com timeline

Para referência detalhada: `~/.claude/playbooks/incident-response.md`

---

### 5. "Preciso revisar código antes do merge"

```
> /dev-review src/main/java/com/example/order/
```

Review multi-perspectiva:
- `code-reviewer` → qualidade, padrões, segurança
- `architect` → decisões de design, acoplamento
- `dba` → queries N+1, índices faltando

Alternativa com plugin (review avançado com TDD e debugging skills):

```
> /code-review
```

---

### 6. "Quero migrar o monólito"

Sequência completa do Strangler Fig:

```
# Fase 0: Entender o monólito
> /migration-discovery

# Fase 2: Criar seams no módulo de pagamentos
> /migration-prepare payment

# Fase 3: Extrair como microsserviço
> /migration-extract payment

# Provisionar infra
> /devops-provision payment-service aws

# Testes de contrato (garantir paridade)
> /qa-contract payment-service

# Fase 5: Desligar no monólito
> /migration-decommission payment
```

7 agents especializados coordenados pelo `tech-lead`.

---

### 7. "Preciso testar segurança da API"

```
> /qa-security order-service
```

O `security-test-engineer` executa:
- OWASP Top 10 (injection, auth bypass, IDOR, XSS, misconfig)
- Testes automatizados (acesso sem token, token expirado, acesso cross-tenant)
- Gera testes integráveis ao CI como quality gate

---

### 8. "Preciso otimizar custos cloud"

```
> /devops-finops
```

O `finops-engineer` analisa:
- Custo por categoria (compute, DB, networking, storage)
- Recursos over-provisioned (rightsizing candidates)
- Waste (ELBs idle, EBS unattached, snapshots órfãos)
- Cobertura de Savings Plans / Reserved Instances

Para referência detalhada: `~/.claude/playbooks/cost-optimization.md`

---

### 9. "Preciso arquitetar algo na AWS"

```
> /devops-cloud order-service
```

O `aws-cloud-engineer` projeta:
- Arquitetura com serviços AWS (EKS, RDS, ALB, etc.)
- Trade-offs (EKS vs ECS, Aurora vs RDS, NAT vs VPC Endpoints)
- Estimativa de custo por componente
- IAM policies least privilege
- Validação de segurança pelo `security-ops`

---

### 10. "Quero configurar GitOps"

```
> /devops-gitops order-service
```

O `gitops-engineer` configura:
- ArgoCD Application manifest
- Sync policy (auto-sync, prune, self-heal)
- Argo Rollouts para canary deployment
- Image Updater para write-back automático de tag

---

### 11. "Preciso de um prompt otimizado"

```
> /gen-prompt prompt "backend-dev implementar autenticação JWT com refresh token e RBAC"
```

O `prompt-engineer` gera um prompt otimizado que:
- Usa o vocabulário e patterns que o `backend-dev` espera
- Inclui contexto do projeto (Java version, hexagonal, Spring Security)
- Define output esperado (código, migration, testes)
- Referencia skills relevantes

### 12. "Quero criar um agent novo"

```
> /gen-prompt agent "especialista em Apache Kafka: producers com Outbox Pattern, consumers idempotentes, DLQ, schema registry, consumer groups"
```

O `prompt-engineer` gera o agent completo:
- YAML frontmatter com name, description, tools, model, color
- System prompt com identidade, responsabilidades, regras
- Checklist de qualidade
- Alinhado com o ecossistema existente

---

## Todos os Slash Commands

### Nativos do Claude Code (21)

| Comando | Para quê |
|---------|----------|
| `/help` | Ajuda geral |
| `/clear` | Limpa a sessão |
| `/compact` | Comprime histórico (libera contexto) |
| `/memory` | Edita memória persistente |
| `/cost` | Custo de tokens da sessão |
| `/doctor` | Diagnóstico da instalação |
| `/init` | Inicializa projeto (cria CLAUDE.md) |
| `/login` `/logout` | Autenticação |
| `/bug` | Reporta bug para Anthropic |
| `/review` | Code review nativo |
| `/pr-comments` | Puxa comentários de PR do GitHub |
| `/vim` | Alterna modo vim |
| `/agents` | Lista agentes disponíveis |
| `/plugin` | Gerenciador de plugins |
| `/plugin install` / `uninstall` / `list` / `update` | Gestão de plugins |
| `/plugin marketplace add` / `list` / `remove` | Gestão de marketplaces |

### Pack Dev (6)

| Comando | Para quê | Exemplo |
|---------|----------|---------|
| `/dev-feature` | Implementar feature completa | `/dev-feature "endpoint de cancelamento"` |
| `/dev-bootstrap` | Criar serviço do zero | `/dev-bootstrap order-service` |
| `/full-bootstrap` | Bootstrap completo (3 packs) | `/full-bootstrap order-service aws` |
| `/dev-review` | Review multi-perspectiva | `/dev-review src/main/java/com/example/` |
| `/dev-refactor` | Refatoração segura | `/dev-refactor OrderService` |
| `/dev-api` | Design de API / OpenAPI | `/dev-api orders` |

### Pack QA (8)

| Comando | Para quê | Exemplo |
|---------|----------|---------|
| `/qa-audit` | Auditoria de qualidade | `/qa-audit` |
| `/qa-generate` | Gerar testes | `/qa-generate CreateOrderUseCase` |
| `/qa-review` | Review de testes | `/qa-review src/test/` |
| `/qa-performance` | Load/stress test | `/qa-performance order-service` |
| `/qa-flaky` | Diagnosticar flaky tests | `/qa-flaky OrderRepositoryTest` |
| `/qa-contract` | Testes de contrato | `/qa-contract order-service` |
| `/qa-security` | Testes OWASP | `/qa-security order-service` |
| `/qa-e2e` | Testes end-to-end | `/qa-e2e "checkout completo"` |

### Pack DevOps (11)

| Comando | Para quê | Exemplo |
|---------|----------|---------|
| `/devops-provision` | Infra completa | `/devops-provision order-service aws` |
| `/devops-pipeline` | CI/CD | `/devops-pipeline order-service` |
| `/devops-observe` | Observabilidade | `/devops-observe order-service` |
| `/devops-incident` | Gestão de incidentes | `/devops-incident "503 intermitente"` |
| `/devops-audit` | Auditoria de infra | `/devops-audit` |
| `/devops-dr` | Disaster recovery | `/devops-dr order-service` |
| `/devops-finops` | Otimização de custos | `/devops-finops` |
| `/devops-gitops` | ArgoCD / GitOps | `/devops-gitops order-service` |
| `/devops-cloud` | Arquitetura AWS | `/devops-cloud order-service` |
| `/devops-mesh` | Service mesh | `/devops-mesh order-service` |

### Pack Data (2)

| Comando | Para quê | Exemplo |
|---------|----------|---------|
| `/data-optimize` | Query lenta, índices | `/data-optimize "SELECT ... FROM orders"` |
| `/data-migrate` | Migrations SQL | `/data-migrate "add column discount"` |

### Pack Migration (4)

| Comando | Para quê | Exemplo |
|---------|----------|---------|
| `/migration-discovery` | Mapear monolito | `/migration-discovery` |
| `/migration-prepare` | Preparar decomposição | `/migration-prepare payment` |
| `/migration-extract` | Extrair microsserviço | `/migration-extract payment` |
| `/migration-decommission` | Desativar legado | `/migration-decommission payment` |

### Plugin Commands (5)

| Comando | Plugin | Para quê |
|---------|--------|----------|
| `/brainstorm` | superpowers | Sessão de brainstorming visual |
| `/write-plan` | superpowers | Escrever plano estruturado |
| `/execute-plan` | superpowers | Executar plano existente |
| `/new-sdk-app` | agent-sdk-dev | Scaffold de agent SDK app |
| `/code-review` | code-review | Review automatizado |

### Utility Command (1)

| Comando | Para quê | Exemplo |
|---------|----------|--------|
| `/gen-prompt` | Gerar prompts, agents, skills, commands, playbooks | `/gen-prompt prompt "backend-dev implementar JWT"` |

---

## Os 5 Times

### 🛠️ Dev Team — Desenvolvimento Backend

| Agent | Especialidade |
|-------|---------------|
| `architect` | Design, ADRs, trade-offs, patterns |
| `backend-dev` | Java 8/21/25+, hexagonal, Kafka, cache, multi-tenancy |
| `api-designer` | OpenAPI, REST, Problem Details, versioning |
| `devops-engineer` | Docker, Helm, CI basics para contexto dev |
| `code-reviewer` | Qualidade, segurança, padrões |
| `refactoring-engineer` | Refatoração segura, complexidade |

### 🧪 QA Team — Testes e Qualidade

| Agent | Especialidade |
|-------|---------------|
| `qa-lead` | Estratégia, quality gates, priorização |
| `unit-test-engineer` | JUnit 5, Mockito, TDD |
| `integration-test-engineer` | Testcontainers, Spring Boot Test |
| `contract-test-engineer` | Pact, Spring Cloud Contract |
| `performance-engineer` | Gatling, k6, load/stress/soak |
| `e2e-test-engineer` | RestAssured, Playwright |
| `test-automation-engineer` | Geração, flaky detection, Pitest |
| `security-test-engineer` | OWASP, auth bypass, IDOR, fuzzing |

### ⚙️ DevOps Team — Infraestrutura e SRE

| Agent | Especialidade |
|-------|---------------|
| `devops-lead` | Estratégia de plataforma |
| `iac-engineer` | Terraform/OpenTofu, modules, state |
| `cicd-engineer` | GitHub Actions, pipelines, quality gates |
| `kubernetes-engineer` | Workloads, autoscaling, spot, networking |
| `observability-engineer` | Prometheus, Grafana, Loki, SLOs |
| `security-ops` | Vault, NetworkPolicy, RBAC, hardening |
| `service-mesh-engineer` | Istio/Linkerd, mTLS, canary |
| `sre-engineer` | Incidents, postmortems, chaos, DR |
| `aws-cloud-engineer` | EKS, ECS, RDS, IAM, VPC |
| `finops-engineer` | Custos, rightsizing, Savings Plans |
| `gitops-engineer` | ArgoCD/FluxCD, progressive delivery |

### 🗄️ Data Team — Banco de Dados

| Agent | Especialidade |
|-------|---------------|
| `dba` | Schema design, Flyway, JPA/Hibernate |
| `database-engineer` | PostgreSQL, RDS/Aurora, VACUUM, DynamoDB |
| `mysql-engineer` | MySQL 8.x, MariaDB, pt-osc, gh-ost, GTID |

### 🔮 Utility — Prompt Engineering

| Agent | Especialidade |
|-------|---------------|
| `prompt-engineer` | Geração e otimização de prompts, agents, skills, commands, playbooks |

### 🏗️ Migration Team — Monólito → Microsserviços

| Agent | Especialidade |
|-------|---------------|
| `tech-lead` | Coordenação, ADRs, priorização |
| `domain-analyst` | Bounded contexts, Event Storming |
| `backend-engineer` | Seams, extração, Strangler Fig |
| `data-engineer` | Data split, CDC, dual-write |
| `platform-engineer` | Routing, shadow traffic, canary |
| `qa-engineer` | Parity tests, regression |
| `security-engineer` | Auth distribution por serviço |

---

## Skills Passivas (28)

Skills são ativadas automaticamente por contexto — quando Claude trabalha num domínio, a skill relevante é carregada sem você precisar fazer nada.

| Categoria | Skills |
|-----------|--------|
| ☁️ Cloud | aws, kubernetes, terraform, argocd, istio, database, mysql |
| 🐳 Docker | docker, docker-ci, docker-security |
| 💻 Dev | java (8/21/25+), nodejs, python, frontend, api-design, testing |
| 🔧 CI/CD | ci-cd, git, github-actions, release-management, workflows |
| 🔒 Ops | finops, incidents, monitoring-as-code, networking, observability, secrets-management, security |

Gerenciar skills:

```bash
~/.claude/skills/skill-helper.sh list          # listar todas
~/.claude/skills/skill-helper.sh show java     # ver conteúdo
~/.claude/skills/skill-helper.sh search kafka  # buscar keyword
~/.claude/skills/skill-helper.sh validate java # validar seções
```

---

## Playbooks Operacionais (12)

Guias passo-a-passo para operações críticas. Marcus os sugere quando o contexto pede.

| Playbook | Quando usar |
|----------|-------------|
| `incident-response.md` | Outage, latência alta, serviço fora do ar |
| `rollback-strategy.md` | Deploy com problemas, reverter rápido |
| `database-migration.md` | Schema change complexa, zero-downtime |
| `secret-rotation.md` | Rotação de credenciais, secret vazado |
| `security-audit.md` | Auditoria pré-release, compliance |
| `terraform-plan-apply.md` | Terraform em produção com segurança |
| `k8s-deploy-safe.md` | Deploy seguro em Kubernetes |
| `cost-optimization.md` | Reduzir custos cloud |
| `dr-drill.md` | Simular disaster recovery |
| `dr-restore.md` | Restore real de DR |
| `dependency-update.md` | Atualizar dependências com segurança |
| `network-troubleshooting.md` | Debug de rede, DNS, VPC |

---

## Plugins

Plugins estendem o ecossistema com capabilities extras. Para instalar:

```bash
# Plugin manager
/plugin

# Instalar do marketplace oficial
/plugin install superpowers@claude-plugins-official
/plugin install playwright@claude-plugins-official
/plugin install qodo-skills@claude-plugins-official
/plugin install frontend-design@claude-plugins-official
/plugin install agent-sdk-dev@claude-plugins-official
```

| Plugin | O que adiciona |
|--------|---------------|
| **superpowers** | `/brainstorm`, `/write-plan`, `/execute-plan` + skills TDD, debugging, code-review |
| **agent-sdk-dev** | `/new-sdk-app` + verificadores Python/TS para Agent SDK |
| **code-review** | `/code-review` automatizado |
| **frontend-design** | Skill passiva para frontend/UI de alta qualidade |
| **playwright** | Skill passiva para automação de browser e E2E |
| **qodo-skills** | Skills passivas para regras de teste e PR resolver |

---

## Connectors (MCP)

Conecte Claude a ferramentas externas via https://claude.com/connectors :

- **Comunicação:** Slack, Gmail, Microsoft 365
- **Projeto:** Asana, Linear, Jira, Monday.com
- **Design:** Figma, Canva (interactive)
- **Engenharia:** GitHub, Hex, Amplitude
- **Custom:** qualquer remote MCP server

---

## Fluxos do Dia a Dia

### Manhã — começar o dia

```bash
claude --agent marcus
> o que tenho pra fazer hoje?
# Marcus verifica o projeto, sugere próximos passos
```

### Feature nova (ciclo completo)

```
> /dev-feature "adicionar webhook de notificação no checkout"
> /qa-generate CheckoutWebhookUseCase
> /dev-review src/main/java/com/example/checkout/
> /qa-audit
```

### Hardening pré-release

```
> /qa-audit
> /qa-security order-service
> /devops-audit
> /qa-performance order-service
```

### Problema em produção

```
> /devops-incident "latência p99 subiu de 200ms para 3s no payment-service"
# Depois de resolver:
> /data-optimize "SELECT ... FROM payments WHERE ..."
```

### Projeto Java 8 legado

```
> preciso corrigir um bug no módulo de billing (Java 8)
# Marcus detecta Java 8 no pom.xml
# backend-dev adapta automaticamente (sem records, sem virtual threads)
# sugere migração para 21 quando oportuno
```

---

## Estrutura de Arquivos

```
~/.claude/
├── CLAUDE.md                       # Instruções globais
├── agents/                         # 36 agents (flat)
│   ├── marcus-agent.md             # Orquestrador global
│   ├── architect.md                # Dev pack
│   ├── backend-dev.md              # Dev pack
│   ├── kubernetes-engineer.md      # DevOps pack
│   ├── prompt-engineer.md          # Utility
│   ├── ... (33 mais)
│   └── packs-reference/            # Docs dos packs (README, CLAUDE.md)
├── commands/                       # 31 slash commands (flat)
│   ├── dev-feature.md
│   ├── full-bootstrap.md
│   ├── devops-incident.md
│   ├── gen-prompt.md
│   ├── ... (27 mais)
├── skills/                         # 28 skills passivas
│   ├── application-development/    # java, nodejs, python, frontend, api-design, testing
│   ├── cloud-infrastructure/       # aws, kubernetes, terraform, argocd, istio, database, mysql
│   ├── containers-docker/          # docker, docker-ci, docker-security
│   ├── devops-cicd/                # ci-cd, git, github-actions, release-management, workflows
│   ├── operations-monitoring/      # finops, incidents, monitoring-as-code, networking, observability, secrets-management, security
│   └── skill-helper.sh
├── playbooks/                      # 12 playbooks operacionais
├── checks/                         # Micro-checklists (populate as needed)
└── plugins/                        # Gerenciado pelo Claude Code
```

---

## FAQ

**Marcus é obrigatório?**
Não. Você pode chamar qualquer agent direto (`claude --agent backend-dev`) ou qualquer command (`/dev-feature`). Marcus é o atalho — ele roteia pra você.

**Posso usar num projeto Node.js/Python?**
Sim. As skills de nodejs, python e frontend ativam automaticamente. Os agents de Dev pack focam em Java, mas o `architect` e `code-reviewer` são agnósticos.

**Quanto custa em tokens?**
Cada agent abre um context window próprio. Multi-agent workflows usam ~4-7x mais tokens que sessão single. Use `context: fork` (já configurado nos agents pesados) para isolar e `/compact` para comprimir.

**Posso adicionar meus próprios agents?**
Sim. Crie um `.md` com YAML frontmatter em `~/.claude/agents/` e ele aparece automaticamente.

**Posso criar meus próprios prompts/agents/skills?**
Sim. Use `/gen-prompt` — ele gera qualquer artefato alinhado ao ecossistema. Ex: `/gen-prompt agent "especialista em GraphQL"`

**Como atualizar?**
Baixe a nova versão e rode `install.sh` novamente. Ele faz backup do existente antes de sobrescrever.

# Plugins
  claude plugin install code-review
  claude plugin install superpowers@claude-plugins-official
  claude plugin install frontend-design@claude-plugins-official
  claude plugin install qodo-skills@claude-plugins-official
  claude plugin install agent-sdk-dev@claude-plugins-official
  claude plugin install playwright@claude-plugins-official