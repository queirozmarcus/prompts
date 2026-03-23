# Workflows — Execution Engine para Marcus Fase 4

**Versao:** 1.0.0

Workflows sao definicoes YAML que Marcus interpreta na Fase 4 (Execucao). Substituem a orquestracao ad-hoc por um engine com dependency graph, paralelismo, quality gates, retry, rollback e status tracking granular.

## Como Funciona

```
Fase 2 (Plan):
  Marcus busca template em workflows/ que match a tarefa
  → Match exato: usa template com params resolvidos
  → Match parcial: adapta steps do template
  → Sem match: gera YAML ad-hoc inline no plan file

Fase 4 (Execucao):
  Marcus carrega o workflow (template ou ad-hoc)
  → Topological sort dos steps por depends_on
  → Executa steps prontos (dependencias completas)
  → Steps sem dependencia mutua rodam em paralelo
  → Valida outputs e checks entre steps
  → Persiste status no plan file apos cada step
```

## Diretorio

```
~/.claude/workflows/
├── README.md                                    # Este arquivo
├── feature-implementation.workflow.yaml          # Feature end-to-end
├── service-bootstrap.workflow.yaml               # Bootstrap completo (Dev+QA+DevOps)
├── infrastructure-provision.workflow.yaml         # IaC+K8s+CI/CD+Obs+Sec
└── migration-extract.workflow.yaml               # Strangler Fig extraction
```

## Schema YAML

```yaml
workflow:
  name: string              # kebab-case, unico
  description: string       # O que o workflow faz
  version: semver           # 1.0.0
  author: string            # Quem criou (marcus, user)
  tags: [string]            # Para busca/matching

  params:                   # Variaveis injetadas em runtime
    - name: string
      required: boolean
      default: string       # Opcional
      description: string

  defaults:                 # Defaults globais, overridable por step
    retry:
      max_attempts: int     # Default: 1
      strategy: immediate | backoff
      backoff_multiplier: int
    on_fail: abort | warn | retry | rollback_to:<step_id>
    timeout: int            # Segundos (soft limit)

  steps:                    # Execucao por dependency graph
    - id: string            # Unico no workflow
      type: agent | command | check | parallel | conditional | report
      description: string
      depends_on: [step_id] # Steps que devem completar antes
      outputs: [...]        # Artefatos esperados
      checks: [...]         # Quality gates
      retry: {...}          # Override do default
      on_fail: string       # Override do default
      timeout: int          # Override do default
```

## Step Types

### `type: agent` — Delegar para um agent

```yaml
- id: implement
  type: agent
  agent: backend-dev          # Agent de ~/.claude/agents/
  prompt: |                   # Template com {{param}}
    Implementar "{{feature_description}}" seguindo hexagonal.
  model_override: opus        # Opcional: override do modelo default
  outputs:
    - path: "src/main/java/**/*.java"
      description: "Arquivos de implementacao"
  checks: ["Code compiles without errors"]
  retry: { max_attempts: 2, strategy: immediate }
```

### `type: command` — Executar slash command existente

```yaml
- id: bootstrap
  type: command
  command: dev-bootstrap      # Command de ~/.claude/commands/
  arguments: "{{service_name}}"
  outputs:
    - path: "src/main/java/**/Application.java"
```

### `type: check` — Quality gate

```yaml
# Referencia a check existente
- id: validate_probes
  type: check
  check_ref: probes-defined   # De ~/.claude/checks/
  on_fail: abort

# Check inline
- id: validate_tests
  type: check
  check_inline: "All tests pass"
  verify_command: "./mvnw test -q"
  on_fail: abort
```

### `type: parallel` — Execucao concorrente

```yaml
- id: infra
  type: parallel
  depends_on: [code_complete]
  steps:
    - id: helm
      type: agent
      agent: kubernetes-engineer
      prompt: "Criar Helm chart..."
    - id: pipeline
      type: agent
      agent: cicd-engineer
      prompt: "Criar pipeline CI/CD..."
    - id: observability
      type: agent
      agent: observability-engineer
      prompt: "Configurar monitoramento..."
  on_fail: abort  # Se QUALQUER sub-step falhar
```

### `type: conditional` — Execucao condicional

```yaml
- id: kafka_setup
  type: conditional
  condition: "contains(read('application.yml'), 'kafka')"
  then:
    id: setup_kafka
    type: agent
    agent: platform-engineer
    prompt: "Configurar infra Kafka..."
  else:
    id: skip_kafka
    type: report
    template: "Sem dependencia Kafka, pulando."
```

### `type: report` — Resumo final

```yaml
- id: summary
  type: report
  depends_on: [review, tests]
  template: |
    ## Concluido: {{feature_description}}
    Steps: {{workflow.steps_completed}} / {{workflow.steps_total}}
    ### Proximos passos
    - `/qa-audit` para analise de cobertura
```

## Outputs — Contratos entre Steps

```yaml
outputs:
  # Arquivo (Marcus valida via Glob)
  - path: "src/main/resources/db/migration/V*__*.sql"
    optional: false           # Default: false
    description: "Flyway migration"

  # Artefato textual (Marcus extrai da resposta do agent)
  - artifact: "review_findings"
    type: text                # text | json | list
    description: "Code review findings"

  # Diretorio (Marcus valida que nao esta vazio)
  - path: "helm/{{service_name}}/templates/"
    type: directory
```

Steps referenciam outputs anteriores: `{{step.<id>.outputs.<name>}}`

## Failure Handling

```
Step falha
  ├─ on_fail: retry
  │   ├─ attempts < max_attempts → re-executa
  │   └─ esgotou tentativas → escala para abort
  ├─ on_fail: warn
  │   └─ loga warning, status: warned, continua
  ├─ on_fail: abort
  │   └─ PARA workflow, reporta ao usuario, salva status
  └─ on_fail: rollback_to:<step_id>
      └─ oferece re-execucao a partir do step indicado
```

## Status Model

```
Step:     pending → running → completed | warned | failed
Failed:   failed → retry(running) | aborted | rollback
Workflow: DRAFT → APPROVED → RUNNING → COMPLETED | ABORTED | PAUSED
```

## Plan File com Workflow

```markdown
# Plano: {titulo}
Data: {timestamp}
Status: RUNNING
Workflow: {nome}.workflow.yaml v{version}

## Params
- feature_description: "..."

## Steps
| # | Step | Agent/Command | Status | Started | Completed | Notes |
|---|------|--------------|--------|---------|-----------|-------|
| 1 | design | architect | completed | 14:30 | 14:32 | ADR gerado |
| 2 | api | api-designer | running | 14:32 | — | — |

## Checks
- [x] Architecture documented (design)
- [ ] Tests pass (generate_tests) — pending

## Failure Log
(none)
```

## Criando Novos Workflows

1. Criar `{kebab-case-name}.workflow.yaml` em `~/.claude/workflows/`
2. Seguir o schema acima
3. Referenciar agents existentes em `~/.claude/agents/`
4. Referenciar checks existentes em `~/.claude/checks/`
5. Validar: `~/.claude/validate-ecosystem.sh --section workflows`

## Promovendo Ad-hoc para Template

Se um workflow ad-hoc (gerado inline) se mostrar reutilizavel:
```
/gen-prompt workflow "descricao do workflow"
```
O prompt-engineer gera o template YAML otimizado.

---
**Usado por:** Agent-Marcus (Fase 2: template matching, Fase 4: execution engine)
**Referencia:** `~/.claude/agents/marcus.md` secao "Workflow Engine"
