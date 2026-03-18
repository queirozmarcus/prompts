#!/bin/bash
set -euo pipefail

echo "═══════════════════════════════════════"
echo "  Instalação do Ecossistema Codex CLI"
echo "  Marcus v6 + specialists + workflows"
echo "═══════════════════════════════════════"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${CODEX_HOME:-$HOME/.codex}"
BACKUP_BASE="${TARGET%/}-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d "$TARGET" ]; then
  echo "⚠ $TARGET já existe. Criando backup em $BACKUP_BASE"
  cp -r "$TARGET" "$BACKUP_BASE"
  echo "✓ Backup criado"
  echo ""
fi

mkdir -p "$TARGET"/{agents,workflows,skills,playbooks,checks,legacy}

cp "$SCRIPT_DIR/AGENTS.md" "$TARGET/AGENTS.md"
echo "✓ AGENTS.md instalado"

cp "$SCRIPT_DIR/agents/"*.md "$TARGET/agents/"
echo "✓ $(find "$TARGET/agents" -maxdepth 1 -name '*.md' | wc -l) specialists instalados"

cp "$SCRIPT_DIR/workflows/"*.md "$TARGET/workflows/"
echo "✓ $(find "$TARGET/workflows" -maxdepth 1 -name '*.md' | wc -l) workflows instalados"

if [ -d "$TARGET/skills" ]; then
  echo "⚠ skills/ já existe — mesclando sem sobrescrever arquivos locais"
  cp -rn "$SCRIPT_DIR/skills/"* "$TARGET/skills/" 2>/dev/null || true
else
  cp -r "$SCRIPT_DIR/skills" "$TARGET/skills"
fi
echo "✓ $(find "$TARGET/skills" -name 'SKILL.md' | wc -l) skills instaladas"

cp "$SCRIPT_DIR/playbooks/"*.md "$TARGET/playbooks/"
echo "✓ $(find "$TARGET/playbooks" -maxdepth 1 -name '*.md' | wc -l) playbooks instalados"

if [ -d "$SCRIPT_DIR/checks" ]; then
  cp -r "$SCRIPT_DIR/checks/." "$TARGET/checks/" 2>/dev/null || true
fi
echo "✓ checks sincronizados"

if [ -d "$SCRIPT_DIR/legacy" ]; then
  cp -r "$SCRIPT_DIR/legacy/." "$TARGET/legacy/"
  echo "✓ material legado arquivado"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  ✅ INSTALAÇÃO COMPLETA"
echo "═══════════════════════════════════════"
echo ""
echo "Destino:"
echo "  $TARGET"
echo ""
echo "Verificações rápidas:"
echo "  find \"$TARGET/agents\" -maxdepth 1 -name '*.md' | wc -l"
echo "  find \"$TARGET/workflows\" -maxdepth 1 -name '*.md' | wc -l"
echo "  find \"$TARGET/skills\" -name 'SKILL.md' | wc -l"
echo ""
echo "Use o workspace com Codex CLI; Marcus será carregado via AGENTS.md."
