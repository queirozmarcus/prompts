# Codex CLI Agent Ecosystem

Marcus v6 is the default gateway for this repository in Codex CLI. The ecosystem preserves the original specialist packs for Dev, QA, DevOps, Data, and monolith migration, but the runtime model is now native to Codex: `AGENTS.md` as the entrypoint, `agents/` for specialists, `workflows/` for multi-step orchestration, `skills/**/SKILL.md` for passive guidance, and `playbooks/` for reusable operating procedures.

## Structure

- `AGENTS.md`: root behavior for Codex, with Marcus as the router.
- `agents/`: 36 specialist guides, such as `architect`, `backend-dev`, `sre-engineer`, and `tech-lead`.
- `workflows/`: execution recipes for aliases like `dev-feature`, `qa-audit`, and `devops-incident`.
- `skills/`: domain-specific Codex skills grouped by category.
- `playbooks/`: operational runbooks for incidents, rollback, cost optimization, and migrations.
- `legacy/claude/`: archived Claude-specific docs and pack references.

## Getting Started

```bash
bash install.sh
```

The installer targets `${CODEX_HOME:-$HOME/.codex}` and backs up any previous ecosystem snapshot before copying:

- `AGENTS.md`
- `agents/`
- `workflows/`
- `skills/`
- `playbooks/`
- `checks/`

After installation, open Codex in a project and describe the task naturally. Marcus will classify the request, choose the best specialist or workflow, and fall back to local orchestration if subagent delegation is unavailable in the runtime.

## Usage Patterns

- “Execute the `dev-feature` workflow para adicionar filtro por status”
- “Use o `sre-engineer` para investigar 503 intermitente”
- “Rode o workflow `qa-audit` neste módulo”
- “Planeje a extração com `migration-discovery`”

## Notes

- Skills are now stored as `SKILL.md`, not the previous Claude-specific filename.
- Workflow names are preserved for continuity, but they are invoked by natural language instead of slash commands.
- References to Claude Code remain only under `legacy/claude/`.
