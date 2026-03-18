#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════"
echo "  Instalação do Ecossistema Claude Code"
echo "  Marcus v6 + 35 agents + 27 commands"
echo "  28 skills + 12 playbooks"
echo "═══════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude"

# Backup if exists
if [ -d "$TARGET" ]; then
  BACKUP="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
  echo "⚠ ~/.claude já existe. Criando backup em $BACKUP"
  cp -r "$TARGET" "$BACKUP"
  echo "✓ Backup criado"
  echo ""
fi

# Create structure
mkdir -p "$TARGET"/{agents,commands,playbooks,checks}

# CLAUDE.md
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
echo "✓ CLAUDE.md global"

# Agents (flat — como Claude Code espera)
cp "$SCRIPT_DIR/agents/"*.md "$TARGET/agents/"
echo "✓ $(ls "$TARGET/agents/"*.md | wc -l) agents instalados (flat)"

# Commands (flat)
cp "$SCRIPT_DIR/commands/"*.md "$TARGET/commands/"
echo "✓ $(ls "$TARGET/commands/"*.md | wc -l) commands instalados"

# Skills
if [ -d "$TARGET/skills" ]; then
  echo "⚠ skills/ já existe — mesclando (sem sobrescrever)"
  cp -rn "$SCRIPT_DIR/skills/"* "$TARGET/skills/" 2>/dev/null || true
else
  cp -r "$SCRIPT_DIR/skills" "$TARGET/skills"
fi
echo "✓ $(find "$TARGET/skills" -name 'CLAUDE.md' | wc -l) skills instaladas"

# Playbooks
cp "$SCRIPT_DIR/playbooks/"*.md "$TARGET/playbooks/"
echo "✓ $(ls "$TARGET/playbooks/"*.md | wc -l) playbooks instalados"

# Pack reference (docs, README)
if [ -d "$SCRIPT_DIR/agents/packs-reference" ]; then
  cp -r "$SCRIPT_DIR/agents/packs-reference" "$TARGET/agents/"
  echo "✓ Pack reference docs copiados"
fi

# Validate-agents.sh
[ -f "$SCRIPT_DIR/agents/validate-agents.sh" ] && cp "$SCRIPT_DIR/agents/validate-agents.sh" "$TARGET/agents/"

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ INSTALAÇÃO COMPLETA"
echo "═══════════════════════════════════════"
echo ""
echo "Para começar:"
echo "  claude --agent marcus"
echo ""
echo "Para verificar:"
echo "  ls ~/.claude/agents/*.md | wc -l    # deve ser 36"
echo "  ls ~/.claude/commands/*.md | wc -l  # deve ser 27"
echo "  claude agents                        # lista agents no CLI"
echo ""
echo "Marcus vai fazer varredura do projeto"
echo "e te guiar a partir daí. Bom trabalho! 🚀"
