# ANEXO V -- Manual de Validacao do Ecossistema

**Versao:** v10.2.0
**Script:** `~/.claude/validate-ecosystem.sh`
**Substitui:** `agents/validate-agents.sh` (removido na v10.2.0)

## Visao Geral

O `validate-ecosystem.sh` e o script central de validacao de integridade do ecossistema de agents do Claude Code. Ele verifica agents, commands, skills, playbooks, plugins e as cross-references entre eles -- garantindo que tudo esta coerente e funcional.

**Quando rodar:**
- Apos instalar ou atualizar agents
- Apos criar ou modificar commands, skills ou playbooks
- Apos instalar ou remover plugins
- Antes de commitar mudancas no repositorio de agents
- Como smoke test depois de um upgrade de versao

## Uso Basico

```bash
# Validacao completa (mostra apenas WARN e FAIL)
~/.claude/validate-ecosystem.sh

# Validacao com detalhes (mostra todos os PASS tambem)
~/.claude/validate-ecosystem.sh --verbose

# Ajuda
~/.claude/validate-ecosystem.sh --help
```

## Opcoes

| Flag | Descricao |
|------|-----------|
| `--verbose` | Mostra todos os checks, incluindo PASS e INFO |
| `--section <nome>` | Roda apenas um modulo especifico |
| `--fix` | Auto-corrige problemas quando possivel (ex: remove junk files) |
| `--help` | Exibe ajuda com exemplos |

**Secoes disponiveis para `--section`:**
`agents` | `commands` | `skills` | `playbooks` | `plugins` | `crossrefs` | `inventory` | `workflows`

## Niveis de Resultado

| Nivel | Significado | Exit Code |
|-------|-------------|-----------|
| **PASS** | Check passou (so aparece com `--verbose`) | 0 |
| **WARN** | Problema menor, nao bloqueia | 0 |
| **FAIL** | Problema critico que precisa de correcao | 1 |
| **INFO** | Informacao adicional (so aparece com `--verbose`) | 0 |
| **FIX** | Problema auto-corrigido (com `--fix`) | 0 |

## Os 8 Modulos

### Module 1: Agents

Valida todos os arquivos `*.md` em `~/.claude/agents/` (exceto CLAUDE.md e README.md).

**Checks realizados:**
- Frontmatter YAML presente e valido (delimitado por `---`)
- Campos obrigatorios: `name`, `description`, `tools`, `model`, `version`
- Campo `name` bate com o nome do arquivo (ex: `backend-dev.md` deve ter `name: backend-dev`)
- Campo `model` e um valor conhecido: `sonnet`, `opus`, `haiku` ou `inherit`
- Campo `tools` lista apenas tools conhecidas: `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `Task`, `Agent`, `WebFetch`, `WebSearch`, `NotebookEdit` (tools MCP com prefixo `mcp__` sao permitidas)
- Nao ha colisao de nomes entre agents
- Junk files (Zone.Identifier, .bak, ~) sao reportados como WARN
- Versao de todos os agents e uniforme com a versao do Marcus

**Exemplo — agent com problema:**
```
[FAIL] my-agent: campo obrigatorio 'version' ausente
[WARN] my-agent: model 'gpt4' nao reconhecido (esperado: sonnet opus haiku inherit)
```

**Exemplo — agent saudavel (com --verbose):**
```
[PASS] backend-dev: frontmatter valido
[PASS] backend-dev: campo 'name' presente
[PASS] backend-dev: campo 'description' presente
[PASS] backend-dev: campo 'tools' presente
[PASS] backend-dev: campo 'model' presente
[PASS] backend-dev: campo 'version' presente
[PASS] backend-dev: name bate com filename
[PASS] backend-dev: model 'sonnet' valido
[PASS] backend-dev: tool 'Read' conhecida
[PASS] backend-dev: tool 'Write' conhecida
```

### Module 2: Commands

Valida todos os arquivos `*.md` em `~/.claude/commands/`.

**Checks realizados:**
- Frontmatter YAML presente e valido
- Campos obrigatorios: `name`, `description`
- Campo `name` bate com o nome do arquivo
- Agents referenciados no corpo do command existem em `~/.claude/agents/`
  - Detecta padroes: `sub-agente **nome**`, `sub-agent **nome**`, `Use o **nome**`
- Command tem source no repositorio (nao e "fantasma")
- Campo `argument-hint` presente (recomendado, WARN se ausente)

**Exemplo — command com referencia quebrada:**
```
[FAIL] qa-flaky: agent referenciado 'nome-errado' NAO encontrado em agents/
```

**Exemplo — command fantasma:**
```
[WARN] devops-cloud: instalado sem source no repo (comando fantasma)
```

### Module 3: Skills

Valida todas as skills em `~/.claude/skills/<category>/<name>/CLAUDE.md`.

**Checks realizados:**
- Arquivo CLAUDE.md nao esta vazio
- Secoes obrigatorias presentes:
  - `## Scope`
  - `## Core Principles`
  - `Communication Style`
  - `Expected Output Quality`
  - `Skill type:`
- Conteudo minimo de 50 linhas (WARN se menor)

**Exemplo — skill incompleta:**
```
[FAIL] cloud-infrastructure/aws: secao '## Core Principles' ausente
[WARN] devops-cicd/git: apenas 32 linhas (minimo recomendado: 50)
```

### Module 4: Playbooks

Valida todos os arquivos `*.md` em `~/.claude/playbooks/`.

**Checks realizados:**
- Arquivo nao esta vazio
- Commands referenciados (ex: `/dev-feature`) existem em `~/.claude/commands/`
- Checks referenciados (ex: `checks/probes-defined.md`) existem em `~/.claude/checks/`

**Exemplo — playbook com check faltando:**
```
[WARN] deploy-novo-servico: check 'checks/security-scan.md' referenciado mas nao encontrado
```

### Module 5: Plugins

Detecta plugins instalados e verifica documentacao.

**Checks realizados:**
- Lista plugins em `~/.claude/plugins/` e `~/.claude/plugins/cache/`
- Filtra diretorios internos (marketplaces, cache, context-mode, temp_*)
- Verifica se cada plugin esta documentado no `marcus.md`
- Verifica se cada plugin esta documentado no `CLAUDE.md` global

**Exemplo — plugin nao documentado:**
```
[WARN] my-new-plugin: instalado mas nao encontrado no marcus.md
[WARN] my-new-plugin: instalado mas nao encontrado no CLAUDE.md global
```

### Module 6: Cross-References

Valida a coerencia entre Marcus, CLAUDE.md e os artefatos instalados.

**Checks realizados:**

**6.1 — Marcus cataloga todos os commands**
Cada command instalado deve aparecer no `marcus.md` como `/{command-name}`.
```
[FAIL] Command '/data-migrate' existe mas NAO catalogado no marcus.md
```

**6.2 — Marcus lista todos os agents**
Cada agent instalado (exceto o proprio Marcus) deve ser mencionado no `marcus.md`.
```
[FAIL] Agent 'finops-engineer' existe mas NAO listado no marcus.md
```

**6.3 — Contagens numericas coerentes**
Compara totais reais com numeros declarados no CLAUDE.md global e no marcus.md.
```
[FAIL] Agent count mismatch: real=37, CLAUDE.md=36
[FAIL] Playbook count mismatch: real=13, marcus.md=12
```

**6.4 — Skill names corretos**
Verifica que marcus.md e CLAUDE.md usam nomes completos das skills do superpowers (nao abreviacoes).
```
[WARN] marcus.md usa nome abreviado 'tdd' em vez de 'test-driven-development'
```

**6.5 — Delegation chains**
Valida que agents mencionados em cadeias de delegacao (`agent-a -> agent-b -> agent-c`) existem.
```
[WARN] Chain agent 'old-agent-name' nao encontrado como agent instalado
```

### Module 7: Inventory

Exibe um resumo de totais. Nao gera PASS/FAIL — e apenas informativo.

**Exemplo de output:**
```
  Agents:      37
  Commands:    31  (0 sem source no repo)
  Skills:      28
  Playbooks:   13
  Checks:      7
  Workflows:   4
  Plugins:     7
```

### Module 8: Workflows

Valida todos os arquivos `*.workflow.yaml` em `~/.claude/workflows/`.

**Checks realizados:**
- YAML syntax valido (usa Python `yaml.safe_load` ou fallback basico)
- Campos obrigatorios presentes: `name`, `description`, `version`, `steps`
- Agents referenciados nos steps existem em `~/.claude/agents/`
- Checks referenciados nos steps existem em `~/.claude/checks/`
- DAG valido: nenhum ciclo em `depends_on` (topological sort)
- Step IDs unicos dentro do workflow

**Exemplo — workflow com agent inexistente:**
```
[FAIL] feature-implementation: step 'design' referencia agent 'nome-errado' NAO encontrado em agents/
```

**Exemplo — workflow com ciclo:**
```
[FAIL] service-bootstrap: ciclo detectado em depends_on: step-a -> step-b -> step-a
```

**Exemplo — workflow saudavel (com --verbose):**
```
[PASS] feature-implementation: YAML syntax valido
[PASS] feature-implementation: campos obrigatorios presentes
[PASS] feature-implementation: 7 steps, todos com IDs unicos
[PASS] feature-implementation: todos os agents referenciados existem
[PASS] feature-implementation: DAG valido (sem ciclos)
```

## Exemplos Praticos

### 1. Validacao rapida do dia-a-dia

```bash
~/.claude/validate-ecosystem.sh
```

Output esperado quando tudo esta OK:
```
  ECOSYSTEM VALIDATOR v1.0.0
  2026-03-22 20:35:30

  Module 1: Agents
  Module 2: Commands
  Module 3: Skills
  Module 4: Playbooks
  Module 5: Plugins
  Module 6: Cross-References
  Module 7: Inventory

  Agents:      37
  Commands:    31
  Skills:      28
  Playbooks:   13
  Checks:      4
  Plugins:     5

  RESULTS
  PASS:  1157
  WARN:  0
  FAIL:  0
  Ecosystem is healthy.
```

### 2. Validacao detalhada apos criar um novo agent

```bash
~/.claude/validate-ecosystem.sh --verbose --section agents
```

Util para ver exatamente quais checks passaram para o novo agent.

### 3. Verificar se Marcus conhece tudo apos adicionar um command

```bash
~/.claude/validate-ecosystem.sh --section crossrefs
```

Se o novo command nao estiver documentado no marcus.md:
```
[FAIL] Command '/meu-novo-command' existe mas NAO catalogado no marcus.md
```

**Correcao:** Adicionar o command na secao de routing do `marcus.md`.

### 4. Limpar junk files automaticamente

```bash
~/.claude/validate-ecosystem.sh --fix
```

Remove automaticamente:
- `*Zone.Identifier` (artefatos do WSL)
- `*.bak` (backups)
- `*~` (backups de editores)

```
[FIX ] removido junk file: marcus.md.bak
[FIX ] removido junk file: backend-dev.md:Zone.Identifier
```

### 5. Verificar integridade das skills apos editar uma

```bash
~/.claude/validate-ecosystem.sh --verbose --section skills
```

Garante que a skill editada ainda tem todas as secoes obrigatorias.

### 6. Audit completo antes de um release

```bash
~/.claude/validate-ecosystem.sh --verbose 2>&1 | tee validation-report.txt
```

Gera um relatorio completo salvo em arquivo para revisao.

### 7. Usar em CI/CD ou pre-commit hook

```bash
# No hook pre-commit ou pipeline
if ! ~/.claude/validate-ecosystem.sh; then
    echo "Ecossistema com falhas. Corrija antes de commitar."
    exit 1
fi
```

O script retorna exit code `1` se houver FAILs, `0` caso contrario.

### 8. Combinar flags

```bash
# Verbose + fix + secao especifica
~/.claude/validate-ecosystem.sh --verbose --fix --section agents
```

## Estrutura de Diretorios Validados

```
~/.claude/
  agents/            --> Module 1 (37 agents)
    marcus.md
    backend-dev.md
    architect.md
    ...
  commands/          --> Module 2 (31 commands)
    dev-feature.md
    qa-audit.md
    ...
  skills/            --> Module 3 (28 skills)
    cloud-infrastructure/
      aws/CLAUDE.md
      kubernetes/CLAUDE.md
      ...
    application-development/
      java/CLAUDE.md
      testing/CLAUDE.md
      ...
  playbooks/         --> Module 4 (13 playbooks)
    incident-response.md
    ...
  plugins/           --> Module 5 (7 plugins instalados)
    cache/
      superpowers/
      episodic-memory/
      ...
  checks/            --> Referenciado por Modules 4 e 8 (7 checks)
    probes-defined.md
    resource-limits.md
    tests-pass.md
    ...
  workflows/         --> Module 8 (4 workflow templates)
    feature-implementation.workflow.yaml
    service-bootstrap.workflow.yaml
    ...
  CLAUDE.md          --> Referenciado pelo Module 6 (contagens)
```

## Troubleshooting

### "FATAL: Diretorio de agents nao encontrado"
O diretorio `~/.claude/agents/` nao existe. Instale os agents primeiro.

### FAIL em contagem de agents/commands
Os numeros declarados no `CLAUDE.md` global ou `marcus.md` estao desatualizados. Atualize as contagens para refletir a realidade.

### WARN "instalado sem source no repo"
O command existe em `~/.claude/commands/` mas nao tem arquivo fonte no repositorio de agents. Isso acontece com commands criados manualmente. Nao e critico, mas considere adicionar o source ao repo para versionamento.

### WARN "argument-hint ausente"
O command nao tem `argument-hint` no frontmatter. Adicionar melhora a UX — o hint aparece como placeholder quando o usuario digita o comando.

### FAIL em agent referenciado
Um command menciona um agent que nao existe em `~/.claude/agents/`. Verifique se o nome esta correto ou se o agent foi removido/renomeado.

## Referencia Rapida

```bash
# Tudo (rapido)
~/.claude/validate-ecosystem.sh

# Tudo (detalhado)
~/.claude/validate-ecosystem.sh --verbose

# So agents
~/.claude/validate-ecosystem.sh --section agents

# So commands
~/.claude/validate-ecosystem.sh --section commands

# So skills
~/.claude/validate-ecosystem.sh --section skills

# So playbooks
~/.claude/validate-ecosystem.sh --section playbooks

# So plugins
~/.claude/validate-ecosystem.sh --section plugins

# So cross-references
~/.claude/validate-ecosystem.sh --section crossrefs

# So inventario
~/.claude/validate-ecosystem.sh --section inventory

# So workflows
~/.claude/validate-ecosystem.sh --section workflows

# Auto-fix
~/.claude/validate-ecosystem.sh --fix

# Relatorio completo em arquivo
~/.claude/validate-ecosystem.sh --verbose 2>&1 | tee report.txt

# Pre-commit gate
~/.claude/validate-ecosystem.sh || exit 1
```
