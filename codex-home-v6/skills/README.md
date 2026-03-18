# Skills – Codex CLI

This directory contains passive skills used by Codex to specialize behavior by domain. Each skill lives in its own folder and exposes a `SKILL.md`.

## Directory Layout

```text
skills/
├── cloud-infrastructure/
├── containers-docker/
├── application-development/
├── devops-cicd/
└── operations-monitoring/
```

## How Skills Apply

- Root behavior comes from `AGENTS.md`.
- Codex loads relevant `SKILL.md` files when the task matches that domain.
- Skills are composable. Typical combinations are `aws + terraform + finops` or `java + api-design + testing`.
- Project-specific behavior should be described in `AGENTS.md`, not in legacy Claude-only config files.

## Usage

- Browse folders to find the right domain skill.
- Keep one `SKILL.md` per skill directory.
- Validate a skill with `bash skills/skill-helper.sh validate <skill-name>`.
- Prefer updating an existing skill when the guidance is domain-wide and reusable.
