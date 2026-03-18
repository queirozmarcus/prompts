# Repository Guidelines

## Structure
- `AGENTS.md`: root runtime instructions for Codex.
- `agents/`: specialist guides.
- `workflows/`: multi-step orchestration recipes.
- `skills/`: passive guidance via `SKILL.md`.
- `playbooks/` and `checks/`: operational references.
- `legacy/claude/`: archived Claude-specific material.

## Validation
- `bash install.sh`: install into `${CODEX_HOME:-$HOME/.codex}`.
- `bash skills/skill-helper.sh list`: inventory skills.
- `bash skills/skill-helper.sh validate <skill>`: validate required sections.
- `find agents workflows playbooks skills -type f | sort`: inspect current content.

## Conventions
- Markdown and Bash only unless a new tool is justified.
- PT-BR for user-facing documentation; English for code and config examples.
- Kebab-case filenames, for example `devops-incident.md` and `security-ops.md`.

## PRs
- Use Conventional Commits in PT-BR when possible.
- Describe the affected ecosystem area and validation commands used.
- Include screenshots only for docs or terminal UX changes.
