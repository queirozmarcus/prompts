# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## What This Repository Is

A library of Claude Code sub-agent definitions organized in **team packs**. No standalone agents — every specialist belongs to a team. The only exception is **Agent-Marcus**, the global orchestrator that routes to the right team.

## Architecture

```
marcus-agent.md              → Global orchestrator (claude --agent marcus)
teams-agents-dev/            → 6 agents, 6 commands  (Java/Spring Boot development)
teams-agents-qa/             → 8 agents, 7 commands  (Test strategy and automation)
teams-agents-devops/         → 11 agents, 8 commands (Infra, CI/CD, SRE, FinOps)
teams-agents-data/           → 3 agents, 2 commands  (PostgreSQL, MySQL, migrations)
teams-agents-monolith-migration/ → 7 agents, 4 commands (Strangler Fig decomposition)
```

**Totals:** 1 orchestrator + 35 pack agents + 1 utility (prompt-engineer) = **37 agents**, **27 repo slash commands** (31 installed with devops-cloud, devops-mesh, qa-security, gen-prompt)

## How to Use

The user always starts with `claude --agent marcus`. Marcus classifies requests and delegates to the right specialist or slash command. The user never needs to know which agent to call — Marcus routes.

## Pack Descriptions

| Pack | Domain | Key Commands |
|------|--------|-------------|
| Dev | Java 21+ / Spring Boot backend | `/dev-feature`, `/dev-bootstrap`, `/full-bootstrap` |
| QA | All test types, quality gates | `/qa-audit`, `/qa-generate`, `/qa-contract` |
| DevOps | K8s, Terraform, CI/CD, SRE, FinOps | `/devops-provision`, `/devops-incident`, `/devops-finops` |
| Data | PostgreSQL, MySQL, schema, migrations | `/data-optimize`, `/data-migrate` |
| Migration | Monolith → microservices | `/migration-discovery`, `/migration-extract` |

## File Formats

### Marcus (global agent) — YAML frontmatter + Markdown
Lives at repository root. Installed to `~/.claude/agents/marcus.md`.

### Team pack agents — YAML frontmatter + Markdown
```yaml
---
name: agent-name
description: "When to use (detailed, with examples)"
tools: Read, Write, Grep, Glob, Bash
model: inherit
color: green
context: fork          # optional — isolates context window
version: 5.0.0
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

### Team pack layout
```
teams-agents-{name}/
  CLAUDE.md
  README.md
  .claude/
    agents/
    commands/
  docs/{domain}/
```

## Commands Installed but Not in Repo

4 commands exist in `~/.claude/commands/` without source files in this repository:

| Command | Pack context | Notes |
|---------|-------------|-------|
| `devops-cloud` | DevOps | AWS cloud architecture analysis |
| `devops-mesh` | DevOps | Service mesh configuration |
| `qa-security` | QA | OWASP security testing |
| `gen-prompt` | Utility | Prompt generation for agents/skills |

These were created manually and installed directly. Consider adding source files to the repo for version control.

## Agent Context Modes

Agents with `context: fork` run in isolated context windows (for heavy code generation). Advisory/read-only agents run inline.

## Workflows

Workflow YAML definitions in `~/.claude/workflows/` provide structured execution for Marcus Phase 4. They define dependency graphs with parallelism, quality gates, retry, and rollback.

| Workflow | Purpose | Steps |
|----------|---------|-------|
| `feature-implementation` | Feature end-to-end | 7 (design -> API+schema -> implement -> review+test) |
| `service-bootstrap` | Bootstrap microservice (all packs) | 11 (Dev -> QA -> DevOps with parallel infra) |
| `infrastructure-provision` | Provision complete infra | 6 (IaC -> K8s -> parallel CI/CD+Obs+Sec) |
| `migration-extract` | Strangler Fig extraction | 8 (analysis -> implement+data -> infra -> test+sec) |

See `~/.claude/workflows/README.md` for the complete YAML schema.

## Validation

```bash
# Full ecosystem validation (agents, commands, skills, playbooks, plugins, cross-refs, workflows)
~/.claude/validate-ecosystem.sh

# Verbose (shows all PASS checks)
~/.claude/validate-ecosystem.sh --verbose

# Validate only agents or workflows
~/.claude/validate-ecosystem.sh --section agents
~/.claude/validate-ecosystem.sh --section workflows
```

See [ANEXO V — Manual de Validacao](../ANEXOV-MANUAL-VALIDACAO-ECO.md) for detailed documentation.

## Naming Conventions

- Java packages: `com.{org}.{service}.{domain|application|adapter.in|adapter.out|config}`
- Kafka topics: `{domain}.{entity}.{action}.v{n}`
- DB migrations: `V{n}__{description}.sql`
- Error codes: `{DOMAIN}-{NNN}`
- Endpoints: `/api/v{n}/{resource}` (kebab-case, plural)
- Terraform: `infra/{cloud}/{environment}/{component}/`

## Changelog

### v5.0.0
- **Zero standalone agents** — all specialists belong to a team pack
- **Marcus as global orchestrator** — always active via `claude --agent marcus`
- **New Data Team pack** (3 agents, 2 commands) — DBA moved from Dev, PostgreSQL + MySQL specialists absorbed
- **DevOps pack expanded** (8→11 agents, 6→8 commands) — absorbed AWS, FinOps, GitOps, enriched 6 agents with standalone content
- **5 pack agents enriched** — merged unique content from standalone equivalents (K8s commands, security AppSec, observability PromQL, CI/CD GitHub Actions patterns, Terraform state operations)
- **Backend-dev enriched** — added Kafka, cache, multi-tenancy, audit/jobs/SLOs sections
- **New commands:** `/devops-finops`, `/devops-gitops`, `/data-optimize`, `/data-migrate`
