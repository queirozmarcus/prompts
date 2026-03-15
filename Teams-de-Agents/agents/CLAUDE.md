# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A library of Claude Code sub-agent definitions. No build system, tests, or deployable code — only `.md` files consumed by Claude Code's agent system.

There are two kinds of content:

**Standalone agents** — single-file specialists at the root level (e.g., `mysql-agent.md`, `security-agent.md`). Each covers one technical domain. Designed to be copied to `~/.claude/agents/` for global availability.

**Team packs** — self-contained subdirectories bundling multiple agents, slash commands, and a project `CLAUDE.md`:

| Pack | Agents | Commands | Domain |
|------|--------|----------|--------|
| `teams-agents-dev/` | 7 | 5 (`/dev-*`) | Java/Spring Boot backend development |
| `teams-agents-qa/` | 8 | 7 (`/qa-*`) | Test strategy and automation |
| `teams-agents-devops/` | 8 | 6 (`/devops-*`) | Kubernetes, IaC, CI/CD, SRE |
| `teams-agents-monolith-migration/` | 7 | 4 (`/migration-*`) | Strangler Fig monolith decomposition |

The three main packs work together: dev → qa → devops. Combined: 23 agents + 18 slash commands. Migration is an independent pack (7 agents + 4 commands).

## Validation & Verification

No build or test system. Validate changes manually:

```bash
# Check YAML frontmatter exists in all team pack agents
for f in teams-agents-*/.claude/agents/*.md; do head -1 "$f" | grep -q '^---$' || echo "MISSING FRONTMATTER: $f"; done

# Check for name collisions across packs
(for d in teams-agents-*/.claude/agents/; do ls "$d"; done) | sort | uniq -d

# Verify commands reference agents that exist in their pack
grep -oP '\*\*([^*]+)\*\*' teams-agents-qa/.claude/commands/qa-audit.md  # then check agent file exists

# Count inventory
for d in teams-agents-*/; do echo "$d: $(ls $d/.claude/agents/*.md | wc -l) agents, $(ls $d/.claude/commands/*.md | wc -l) commands"; done
```

## File Formats

### Standalone agents — plain Markdown

Required sections (in order):
- `## Identity` — role description and user profile
- `## Core Technical Domains` — capabilities organized by subdomain
- `## Thinking Style` — numbered reasoning priorities
- `## Response Pattern` — step-by-step approach per request type
- `## Key Operational Commands` — ready-to-use CLI/SQL snippets
- `## Autonomy Level` — what the agent does freely vs. requires approval for
- Footer: `---\n**Agent type:** Advisory|Consultive|Semi-autonomous|Modular`

### Team pack agents — YAML frontmatter + Markdown

```yaml
---
name: agent-name
description: "When to use this agent (detailed, with examples)"
tools: Read, Write, Grep, Glob, Bash
model: inherit|sonnet|opus
color: green|blue|purple|...
---
```

### Slash commands — YAML frontmatter + Markdown

```yaml
---
name: command-name
description: "What this command does"
argument-hint: "[arguments]"
---
```

Commands orchestrate agents via numbered steps. Pattern: analyze → delegate to sub-agents → consolidate → present summary.

### Team pack layout

```
teams-agents-{name}/
  CLAUDE.md                     # Project context, conventions, principles
  README.md                     # Installation guide and usage examples
  .claude/
    agents/                     # Sub-agent definition files
    commands/                   # Slash command definition files
  docs/{domain}/                # Empty scaffold dirs for generated artifacts
```

## Standalone vs Team Pack Scope

5 standalone agents overlap with team pack agents by design:

| Standalone | Team Pack Equivalent | Difference |
|---|---|---|
| `k8s-platform-agent` | `kubernetes-engineer` (devops) | Standalone: generic K8s/EKS. Pack: Java/Spring Boot workloads |
| `observability-agent` | `observability-engineer` (devops) | Standalone: generic observability. Pack: Spring Boot metrics stack |
| `ci-agent` | `cicd-engineer` (devops) | Standalone: generic GitHub Actions. Pack: includes GitOps/ArgoCD |
| `terraform-infra-agent` | `iac-engineer` (devops) | Standalone: generic Terraform. Pack: multi-cloud + K8s provisioning |
| `backend-java-agent` | `backend-dev` (dev) | Standalone: modular system prompt. Pack: hexagonal architecture focus |

8 standalone agents are unique (no pack equivalent): `agent-marcus` (gateway orchestrator), `incident-agent`, `gitops-agent`, `finops-agent`, `mysql-agent`, `database-agent`, `security-agent`, `aws-platform-agent`.

**Rule of thumb:** standalone = generic/global use; team pack = Java/Spring Boot + K8s context.

## Autonomy Level Conventions

Three levels used consistently:

- **Advisory** — reads and analyzes only; never modifies (e.g., `security-agent`)
- **Consultive** — plans and scripts freely; executes only with explicit approval (e.g., `mysql-agent`)
- **Semi-autonomous** — free for reads and staging; production changes require approval (e.g., `k8s-platform-agent`)

## Editing Guidelines

When creating or modifying agents:

1. **Standalone agents** must include all 6 required sections + footer. No YAML frontmatter.
2. **Team pack agents** must have valid YAML frontmatter with at minimum `name`, `description`, `tools`.
3. **Commands** must reference only agents that exist in the same pack.
4. **Names must be unique** across all packs — no collisions allowed.
5. **Scope notes** (blockquote at top) are required on standalone agents that overlap with pack equivalents.
6. All agent/command content is in **English**. Documentation (READMEs, CLAUDE.md within packs) is in **Portuguese (PT-BR)**.
7. When adding a command to a pack, update both the pack's `CLAUDE.md` (slash commands table) and `README.md`.

## Installing Agents

To a project:
```bash
cp -r teams-agents-dev/.claude/agents/* .claude/agents/
cp -r teams-agents-dev/.claude/commands/* .claude/commands/
```

Globally:
```bash
cp -r teams-agents-dev/.claude/agents/* ~/.claude/agents/
cp -r teams-agents-dev/.claude/commands/* ~/.claude/commands/
```

## Stack Context (within agent content)

Agents assume this reference stack:
- **App:** Java 21+, Spring Boot 3.x, hexagonal architecture
- **Data:** PostgreSQL, Redis, Kafka, Flyway migrations
- **Infra:** AWS (EKS/ECS, RDS, MSK, ElastiCache), Terraform/OpenTofu
- **Platform:** Kubernetes, Helm, ArgoCD/FluxCD, Prometheus + Grafana + Loki
- **CI/CD:** GitHub Actions, GitLab CI

## Naming Conventions (within agent content)

- Java packages: `com.{org}.{service}.{domain|application|adapter.in|adapter.out|config}`
- Kafka topics: `{domain}.{entity}.{action}.v{n}`
- DB migrations: `V{n}__{description}.sql`
- Error codes: `{DOMAIN}-{NNN}` (e.g., `ORDER-001`)
- Endpoints: `/api/v{n}/{resource}` (kebab-case, plural)
- Terraform layout: `infra/{cloud}/{environment}/{component}/`
- K8s manifests: `k8s/{environment}/{service}/`
