# Arquitetura do Agent Ecosystem v8
**Versão:** v8.0.0

## Como Agents, Skills, Commands e Memory Funcionam por Baixo

Este documento explica os mecanismos internos do Claude Code que o ecossistema utiliza: isolamento de contexto, controle de tokens, memória persistente, tools sandboxing e como tudo se conecta.

---

## 1. Context Window — Isolamento Total

Cada subagent roda em seu **próprio context window de 200K tokens**, completamente isolado da conversa principal.

```
┌──────────────────────────────────────────────────┐
│  MARCUS (main session — 200K tokens)              │
│                                                    │
│  Você: "implementa autenticação JWT"               │
│  Marcus: "Isso é /dev-feature. Delegando..."       │
│       │                                            │
│       ▼  Agent tool (delegação)                    │
│  ┌────────────────────────────────────┐            │
│  │  backend-dev (subagent)             │            │
│  │  Context: 200K tokens (ISOLADO)     │            │
│  │  Não vê a conversa do Marcus        │            │
│  │  Só recebe o prompt de delegação    │            │
│  │                                     │            │
│  │  1. Lê pom.xml → detecta Java 21   │            │
│  │  2. Lê estrutura de pacotes         │ ← Ruído   │
│  │  3. Gera SecurityConfig.java        │   fica     │
│  │  4. Gera JwtService.java            │   aqui     │
│  │  5. Gera migration Flyway           │   dentro   │
│  │  6. Gera testes                     │            │
│  │                                     │            │
│  │  → Retorna RESUMO para Marcus ──────│────┐       │
│  └────────────────────────────────────┘    │       │
│                                            │       │
│  Marcus recebe: "Implementei JWT com:      │◄──────┘
│  SecurityConfig, JwtService, migration     │
│  V3__add_users_roles.sql, 5 testes."       │
│                                            │
│  Contexto do Marcus continua LIMPO         │
└──────────────────────────────────────────────────┘
```

**Por que isso importa:**
- O Marcus não é poluído com centenas de linhas de código gerado
- Cada agent pode usar 200K tokens inteiros para sua tarefa
- Múltiplos agents em sequência não acumulam contexto entre si
- `/compact` no Marcus não afeta o trabalho dos subagents

### context: fork

Agents com `context: fork` no frontmatter **sempre** rodam em context isolado, mesmo quando invocados diretamente (não via Marcus). Isso garante que agents pesados como `backend-dev`, `iac-engineer`, `dba` nunca poluem a conversa principal.

**Agents com `context: fork` no ecossistema (16):**
backend-dev, backend-engineer, cicd-engineer, data-engineer, database-engineer, dba, devops-engineer, e2e-test-engineer, iac-engineer, integration-test-engineer, kubernetes-engineer, mysql-engineer, performance-engineer, prompt-engineer, refactoring-engineer, unit-test-engineer

**Agents SEM fork (21):**
Agents advisory/read-only como architect, code-reviewer, qa-lead, devops-lead — rodam inline para que suas análises fiquem visíveis na conversa.

---

## 2. Tokens — Custo e Controle

### Custo por invocação

Cada subagent abre um context window novo. Na prática:

| Modo | Tokens aprox. | Custo relativo |
|------|---------------|----------------|
| Single agent (sem delegação) | 1x | Baseline |
| Marcus → 1 subagent | ~2x | Prompt Marcus + prompt subagent |
| `/dev-feature` (5 agents em sequência) | ~4-7x | Cada agent lê o projeto de novo |
| `/full-bootstrap` (3 packs, 10+ agents) | ~10-15x | Trabalho extenso |

### Como otimizar

1. **Para tarefas simples → agent direto:** Em vez de `/dev-feature`, use `Use o backend-dev para adicionar o campo discount na OrderResponse` — 1 agent em vez de 5.

2. **`/compact` regularmente:** Em sessões longas, comprima o histórico do Marcus.

3. **Agent direto para deep work:** `claude --agent backend-dev` abre sessão dedicada sem Marcus no meio — elimina overhead de routing.

4. **`/cost` para monitorar:** Veja quanto a sessão consumiu.

### Modelo por agent (v8 — atribuição por perfil)

Cada agent tem modelo default atribuído por perfil:

| Perfil | Modelo | Agents | Custo | Quando |
|--------|--------|--------|-------|--------|
| **Analysis** | `haiku` | domain-analyst, qa-lead, devops-lead, finops-engineer | 1x | Leitura, auditoria, análise |
| **Implementation** | `sonnet` | backend-dev, dba, cicd-engineer + 28 outros | 4x | Geração de código, testes, configs |
| **Architecture** | `opus` | architect, tech-lead | 20x | Raciocínio profundo, trade-offs, ADRs |
| **Routing** | `sonnet` | marcus | 4x | Classificação e delegação |

**Override por sessão:** Você pode rodar qualquer agent com modelo diferente:
```bash
claude --model opus --agent marcus     # tudo em Opus (caro, máximo raciocínio)
claude --model opusplan --agent marcus # Opus planeja, Sonnet implementa
claude --model haiku --agent marcus    # tudo em Haiku (barato, exploração)
```

O modelo da sessão (`--model`) tem precedência sobre o modelo do agent quando é mais poderoso. Marcus recomenda override quando a tarefa justifica.

---

## 3. Memory — Conhecimento Persistente

### Como funciona

Agents com `memory:` no frontmatter ganham um **diretório persistente** que sobrevive entre sessões. As primeiras 200 linhas do `MEMORY.md` são injetadas automaticamente no system prompt do agent.

```
~/.claude/agent-memory/
├── architect/
│   └── MEMORY.md          # "Projeto X usa CQRS no módulo de reports..."
├── backend-dev/
│   ├── MEMORY.md          # "Preferência: Lombok só em DTOs legacy..."
│   └── gotchas.md         # "Bug em HikariCP com virtual threads..."
├── code-reviewer/
│   └── MEMORY.md          # "Padrão: sempre verificar N+1 em queries JPA..."
└── sre-engineer/
    ├── MEMORY.md          # "Incidente 2025-03: OOM no payment-service..."
    └── runbooks-notes.md  # "Rollback via Helm funciona melhor que kubectl..."
```

### Scopes

| Scope | Diretório | Versionável | Para quem |
|-------|-----------|-------------|-----------|
| `user` | `~/.claude/agent-memory/{agent}/` | Não | Só você, todos os projetos |
| `project` | `.claude/agent-memory/{agent}/` | Sim (git) | Time inteiro |
| `local` | `.claude/agent-memory/{agent}/` | Não | Só você, só este projeto |

### Quem tem memória no ecossistema

**`memory: user` (8 agents) — conhecimento pessoal cross-project:**

| Agent | O que memoriza |
|-------|---------------|
| `marcus` | Preferências, projetos frequentes, padrões de trabalho |
| `architect` | ADRs, trade-offs, patterns adotados/rejeitados |
| `code-reviewer` | Anti-patterns, issues recorrentes, estilo do dev |
| `backend-dev` | Patterns do codebase, libs, gotchas, workarounds |
| `prompt-engineer` | Prompts eficazes, templates refinados |
| `sre-engineer` | Incidentes passados, runbooks, debugging insights |
| `security-ops` | Vulnerabilidades, hardening patterns, compliance |
| `observability-engineer` | Dashboards, alertas úteis, PromQL patterns |

**`memory: project` (5 agents) — conhecimento do projeto compartilhado:**

| Agent | O que memoriza |
|-------|---------------|
| `dba` | Schema patterns, migrations, index decisions |
| `database-engineer` | Tuning history, VACUUM, performance baselines |
| `mysql-engineer` | Charset fixes, replication configs, pt-osc history |
| `qa-lead` | Quality gates, coverage history, flaky patterns |
| `devops-lead` | Platform decisions, cost history, capacity planning |

**Sem memória (24 agents):** Agents stateless que cada invocação é fresh (test engineers, iac-engineer, cicd-engineer, etc.). O contexto vem do projeto, não de sessões anteriores.

### Como a memória cresce

```
Sessão 1: architect analisa o projeto
  → MEMORY.md: "Projeto usa hexagonal architecture, Spring Boot 3.2, PostgreSQL 16"

Sessão 5: architect avalia CQRS
  → MEMORY.md: "Decisão: NÃO usar CQRS no módulo de orders (complexidade > benefício). ADR-003 criado."

Sessão 12: architect revisa novo módulo
  → MEMORY.md agora tem contexto acumulado, evita re-análise

Sessão 50: MEMORY.md excede 200 linhas
  → Agent faz curadoria: remove notas obsoletas, consolida insights
```

### Dicas de uso

```bash
# Pedir que agent consulte memória antes de começar
> Use o architect para revisar a arquitetura. Consulte sua memória primeiro.

# Pedir que agent atualize memória depois
> Agora salve o que aprendeu na sua memória.

# Ver memória de um agent
cat ~/.claude/agent-memory/architect/MEMORY.md

# Limpar memória de um agent (reset)
rm -rf ~/.claude/agent-memory/architect/
```

---

## 4. Tools — Sandboxing por Agent

Cada agent declara quais tools pode usar. Isso é **enforcement real**, não sugestão.

| Perfil | Tools | Agents |
|--------|-------|--------|
| **Read-only** | Read, Grep, Glob | code-reviewer, qa-lead, devops-lead, architect |
| **Read + Web** | Read, Grep, Glob, Bash, WebFetch | marcus (routing + scan) |
| **Full write** | Read, Write, Edit, Bash, Grep, Glob | backend-dev, dba, iac-engineer, etc. |

**Por que importa:** Um `code-reviewer` **não pode** editar seus arquivos por acidente. Ele só lê. Um `architect` só analisa e gera documentos. Apenas agents de implementação têm Write/Edit.

### Hooks — Controle em lifecycle events

Hooks rodam scripts shell em eventos do ciclo de vida:

```json
// .claude/settings.json
{
  "hooks": {
    "SubagentStop": [{
      "type": "command",
      "command": "~/.claude/hooks/suggest-next-step.sh"
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "type": "command", 
      "command": "~/.claude/hooks/validate-command.sh"
    }]
  }
}
```

| Evento | Quando dispara | Uso |
|--------|---------------|-----|
| `SubagentStop` | Agent termina | Sugerir próximo passo, notificar |
| `Stop` | Sessão termina | Notificação desktop, cleanup |
| `PreToolUse` | Antes de executar tool | Validar comandos perigosos |

---

## 5. Skills — Injeção por Contexto

Skills passivas são carregadas **automaticamente** quando Claude trabalha num domínio relevante.

```
Você edita OrderService.java
  → Claude detecta: Java, Spring Boot
  → Skill application-development/java é carregada no contexto
  → Skill application-development/testing é carregada (se há testes)
  → backend-dev agora tem boas práticas de Java 8/21/25+ como contexto
```

### Skills explícitas no frontmatter

Agents podem declarar skills que são **sempre** injetadas:

```yaml
---
name: api-developer
skills:
  - api-conventions
  - error-handling-patterns
---
```

O conteúdo completo da skill é injetado no system prompt do agent — não apenas disponibilizado.

### Discovery nested

Skills em subdiretórios são descobertas quando Claude trabalha com arquivos naquele diretório:

```
projeto/
├── .claude/skills/         # skills do projeto
│   └── deploy-skill/
└── backend/
    ├── .claude/skills/     # skills do backend
    │   └── api-expert/
    └── src/api.js          # trabalhando aqui → carrega ambas skills
```

---

## 6. Diagrama Completo — Como Tudo Se Conecta

```
┌─────────────────────────────────────────────────────────┐
│  claude --agent marcus                                    │
│                                                           │
│  ┌─── CLAUDE.md (global) ───────────────────────────┐    │
│  │ Code style, git workflow, commit format, etc.     │    │
│  └───────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─── Skills (28, passivas) ────────────────────────┐    │
│  │ Carregadas por contexto: java, k8s, terraform... │    │
│  └───────────────────────────────────────────────────┘    │
│                                                           │
│  Marcus (memory: user) ──────────────────────────────    │
│  │ Recebe pedido → classifica → roteia                   │
│  │                                                        │
│  ├─→ /dev-feature (command)                               │
│  │     ├─→ architect (memory: user, inline)               │
│  │     ├─→ api-designer (stateless, inline)               │
│  │     ├─→ dba (memory: project, fork)                    │
│  │     ├─→ backend-dev (memory: user, fork)               │
│  │     └─→ code-reviewer (memory: user, inline)           │
│  │                                                        │
│  ├─→ /devops-incident (command)                           │
│  │     ├─→ sre-engineer (memory: user, inline)            │
│  │     └─→ observability-engineer (memory: user, inline)  │
│  │         └─→ consulta playbook incident-response.md     │
│  │                                                        │
│  ├─→ /gen-prompt (command)                                │
│  │     └─→ prompt-engineer (memory: user, fork)           │
│  │                                                        │
│  └─→ Agent direto: "Use o kubernetes-engineer para..."    │
│        └─→ kubernetes-engineer (stateless, fork)          │
│            └─→ skill kubernetes carregada por contexto    │
│                                                           │
│  ┌─── Plugins ──────────────────────────────────────┐    │
│  │ superpowers, qodo, playwright, frontend-design   │    │
│  │ Skills e agents de plugin coexistem com locais    │    │
│  └───────────────────────────────────────────────────┘    │
│                                                           │
│  ┌─── Checks + Playbooks ───────────────────────────┐    │
│  │ Referenciados por agents e Marcus durante work    │    │
│  └───────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---


---

## 8. Otimização de Tokens — Guia Prático

O custo médio é ~$6/dev/dia com bons hábitos. Sem bons hábitos, sobe para $20-40/dia. As técnicas abaixo fecham essa diferença.

### 8.1 As 3 Técnicas de Maior Impacto (80% da economia)

#### Técnica 1: Model Selection — usar o modelo certo para a tarefa

```bash
# 80% das tarefas → Sonnet (default, barato e capaz)
claude --agent marcus

# Tarefas simples → Haiku (8x mais barato que Sonnet)
claude --model haiku --agent marcus

# Decisões complexas → Opus (5x mais caro, mas raciocínio superior)
claude --model opus --agent marcus

# Híbrido: Opus para planejar, Sonnet para implementar
# (opusplan usa Opus em plan mode, Sonnet na execução)
claude --model opusplan --agent marcus
```

**Subagents com model específico:** Agents de exploração podem usar Haiku:
```yaml
model: haiku   # agent de busca/leitura — barato
model: sonnet  # agent de implementação — default
model: opus    # agent de raciocínio complexo
model: inherit # usa o modelo da sessão (nosso default)
```

**Nosso ecossistema:** Todos os 37 agents usam `model: inherit`. Para otimizar, rode Marcus com Sonnet (default) e mude para Opus só quando precisa de arquitetura complexa.

**Dica:** Não sabe qual modelo usar? Pergunte ao prompt-engineer:
```
> /gen-prompt prompt "qual modelo para [minha tarefa]"
```
Ele analisa a tarefa e recomenda modelo, effort e modo de execução com custo estimado.

#### Técnica 2: Context Management — manter contexto limpo

```bash
# Comprimir histórico a cada 30-45 min de sessão ativa
/compact

# Comprimir com foco específico
/compact "Foque nos endpoints de Order e ignore exploração de Payment"

# Limpar completamente ao trocar de tarefa
/clear

# Renomear antes de limpar (para poder voltar)
/rename "feature-jwt-auth"
/clear
# Depois: /resume para voltar
```

**Por que importa:** Cada mensagem envia TODO o histórico como input. Sessão de 2h sem compact → centenas de milhares de tokens de contexto acumulado → cada mensagem nova fica cara.

**Nosso ecossistema já ajuda:** `context: fork` nos 16 agents pesados isola automaticamente — output volumoso (código, logs, arquivo) fica no subagent e só o resumo volta.

#### Técnica 3: Prompts Específicos — dizer exatamente o que quer

```
❌ Caro (exploração aberta):
> Olha o código e sugere melhorias

✅ Barato (cirúrgico):
> Em src/main/java/com/example/order/adapter/in/web/OrderController.java,
> refatore o método createOrder (linhas 45-80) para usar o padrão Command
> com validação via Bean Validation
```

```
❌ Caro (múltiplas mensagens):
> Adiciona um log aqui
> E ali também
> E nesse outro lugar

✅ Barato (batch):
> Adicione structured logging em:
> - OrderController.java:45 (entrada do endpoint)
> - CreateOrderUseCase.java:30 (antes de persistir)
> - OrderRepository.java:20 (após query)
```

**Com nosso ecossistema:** Em vez de descrever vagamente, use o command:
```
> /dev-feature "adicionar structured logging no fluxo de criação de pedido"
```
O command é um prompt pré-otimizado que dá contexto estruturado aos agents.

### 8.2 Técnicas de Médio Impacto (15% da economia)

#### Delegação para Subagents (nosso ecossistema já faz)

```
❌ Caro — exploração no contexto principal:
> Leia todos os arquivos em src/ e me explique a arquitetura
(Claude lê 15 arquivos → 150K tokens no seu contexto)

✅ Barato — delegação para subagent:
> Use o architect para analisar a arquitetura do projeto
(architect lê os 15 arquivos no SEU context → retorna resumo de 500 tokens)
```

Economia: 150K tokens → 500 tokens no contexto principal. O subagent paga seus próprios tokens, mas seu context principal fica limpo para o resto da sessão.

#### Effort Level — reduzir raciocínio quando não precisa

```bash
# Reduzir effort para tarefas simples
/effort low     # menos tokens de thinking
/effort medium  # equilíbrio
/effort high    # máximo raciocínio (default)

# Ou limitar tokens de thinking diretamente
MAX_THINKING_TOKENS=8000 claude --agent marcus
```

**Quando usar low:** Formatação, renaming, fixes triviais, linting.
**Quando usar high:** Arquitetura, debugging complexo, refactoring grande.

#### MCP Server Cleanup — remover tools inativos

Cada MCP server conectado adiciona tool definitions ao contexto, mesmo quando idle:

```bash
# Ver o que está consumindo contexto
/context

# Se tem 5 MCP servers → ~55K tokens ANTES de começar a conversar
# Desconecte servers que não está usando
```

**Alternativa mais leve:** Prefer CLI tools (`gh`, `aws`, `kubectl`, `terraform`) sobre MCP servers quando possível — CLIs não adicionam tokens permanentes.

#### CLAUDE.md Enxuto

O CLAUDE.md global é carregado em TODA sessão. Quanto maior, mais tokens consumidos antes de você digitar qualquer coisa.

**Nosso CLAUDE.md:** ~2800 palavras ≈ ~3600 tokens. É aceitável, mas se precisar cortar:
- Mover exemplos extensos para skills (carregadas sob demanda)
- Mover playbooks extensos para `playbooks/` (referência, não contexto)
- Usar `.claude/rules/` para instruções que só se aplicam a certos arquivos

### 8.3 Técnicas Avançadas (5% da economia)

#### Skills como Progressive Disclosure

Nossa arquitetura de skills já faz isso: em vez de carregar TUDO no CLAUDE.md, o conhecimento de domínio está em 28 skills que carregam **sob demanda**.

```
Você edita OrderService.java
  → skill java carrega (~3700 tokens)
  → skill testing carrega se há testes

Você edita terraform/main.tf
  → skill terraform carrega
  → skill java NÃO carrega (não é relevante)
```

Economia: ~15.000 tokens/sessão comparado com carregar tudo no CLAUDE.md.

#### Prompt Caching (automático)

Claude Code usa prompt caching por default — context que não mudou entre mensagens é reutilizado com desconto:
- Cache read: 90% mais barato que input normal
- Funciona melhor com sessões longas e estáveis

**Nosso ecossistema se beneficia:** CLAUDE.md + skills carregadas ficam no cache. Cada mensagem subsequente paga preço de cache, não preço cheio.

#### Batch Operations — agrupar mudanças

```
❌ 5 mensagens separadas (5x inference + context reload):
> Renomeia o campo name para fullName
> Adiciona validação no email
> Cria getter para phone
> Atualiza o toString
> Adiciona teste

✅ 1 mensagem (1x inference):
> Refatore a classe Customer:
> 1. Renomear name → fullName
> 2. Adicionar @Email no campo email
> 3. Adicionar getter para phone
> 4. Atualizar toString com novo campo
> 5. Criar teste unitário para as validações
```

### 8.4 Workflow Diário Otimizado

```
Manhã:
  claude --agent marcus                   # Sonnet por default
  > [tarefa do dia — prompt específico]

A cada 30-45 min:
  /compact                                # comprimir contexto

Ao trocar de tarefa:
  /rename "nome-da-tarefa"
  /clear                                  # contexto limpo

Para tarefa complexa:
  /model opus                             # switch temporário
  > [tarefa de arquitetura/reasoning]
  /model sonnet                           # voltar ao default

Para exploração pesada:
  > Use o architect para analisar X       # subagent isola

Final do dia:
  /cost                                   # ver quanto consumiu
```

### 8.5 Custo Estimado por Operação

| Operação | Tokens aprox. | Custo (Sonnet) |
|----------|---------------|----------------|
| Mensagem simples | 5-10K input | ~$0.02 |
| Leitura de arquivo | 10-50K input | ~$0.05-0.15 |
| Code review (subagent) | 50-150K | ~$0.30-0.79 |
| `/dev-feature` (5 agents) | 200-500K | ~$1-3 |
| `/full-bootstrap` (10+ agents) | 500K-1M+ | ~$3-8 |
| Sessão produtiva de 1 dia | 1-3M total | ~$5-15 |

**Dica:** Use `/cost` ao longo do dia para calibrar intuição.

### 8.6 Variáveis de Ambiente Úteis

```bash
# Limitar tokens de thinking
export MAX_THINKING_TOKENS=8000

# Desabilitar chamadas não-essenciais (sugestões, tips)
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1

# Ver exatamente onde tokens vão (debug)
/cost
/context
```

## 9. Resumo Prático

| Mecanismo | O que faz | Impacto |
|-----------|-----------|---------|
| **context: fork** | Isola context window do agent | Conversa principal limpa |
| **memory: user** | Conhecimento pessoal cross-project | Agent aprende com você |
| **memory: project** | Conhecimento compartilhado do codebase | Time se beneficia |
| **tools restriction** | Limita o que agent pode fazer | Segurança (read-only review) |
| **skills (passive)** | Injeção de boas práticas por domínio | Context enrichment |
| **skills (explicit)** | Pré-carrega skills no agent | Knowledge guarantee |
| **hooks** | Scripts em lifecycle events | Automação e gates |
| **/compact** | Comprimir histórico | Liberar contexto |
| **model: inherit** | Usa modelo da sessão | Consistência |

### O que você controla

```bash
# Ver custo da sessão
/cost

# Comprimir contexto
/compact

# Ver memória de um agent
cat ~/.claude/agent-memory/{agent}/MEMORY.md

# Resetar memória
rm -rf ~/.claude/agent-memory/{agent}/

# Listar agents com suas configs
claude agents

# Mudar modelo da sessão
claude --model opus --agent marcus
```
