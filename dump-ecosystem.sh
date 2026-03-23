#!/bin/bash

################################################################################
# dump-ecosystem.sh
#
# Dump completo de ~/.claude/ para a raiz deste repositório.
#
# Uso: ./dump-ecosystem.sh [opções]
# Opções:
#   --dry-run     Mostra o que seria copiado sem copiar
#   --help        Exibe ajuda
#
# Por padrão (sem opções) realiza dump COMPLETO de todos os componentes.
#
# Autor: Marcus Agent Ecosystem
# Versão: 10.2.0
################################################################################

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Caminhos
CLAUDE_HOME="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DUMP_DIR="$SCRIPT_DIR"
DRY_RUN=0

################################################################################
# Funções utilitárias
################################################################################

show_help() {
    cat << 'EOF'
dump-ecosystem.sh — Dump completo do ecossistema Agent-Marcus

USO:
  ./dump-ecosystem.sh [opções]

OPÇÕES:
  --dry-run     Mostra o que seria copiado sem copiar
  --help        Exibe esta ajuda

COMPORTAMENTO PADRÃO (sem opções):
  Copia TODOS os componentes de ~/.claude/ para a raiz deste repositório:
    agents/     — 37 subagentes
    commands/   — 31 slash commands
    skills/     — 28 passive skills
    playbooks/  — 13 playbooks operacionais
    checks/     — micro-checklists de qualidade
    workflows/  — workflow YAML definitions (Fase 4 do Marcus)
    CLAUDE.md   — instrução global
    README.md   — documentação principal
    ANEXO*.md   — documentação técnica (I–VI)
    VERSION     — versão do ecossistema

EXEMPLOS:
  # Dump completo (padrão)
  ./dump-ecosystem.sh

  # Preview sem copiar
  ./dump-ecosystem.sh --dry-run

EOF
}

log_info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
log_success() { echo -e "${GREEN}✓${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error()   { echo -e "${RED}✗${NC}  $1"; }
log_section() { echo -e "\n${CYAN}▸ $1${NC}"; }

copy_dir() {
    local src="$1"
    local dest="$2"
    local label="$3"

    if [ ! -d "$src" ]; then
        log_warn "Diretório não encontrado, pulando: $src"
        return 0
    fi

    local file_count
    file_count=$(find "$src" -type f 2>/dev/null | wc -l)

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] $label: $file_count arquivos  ($src → $dest)"
        return 0
    fi

    mkdir -p "$dest"
    # Remove destino antes para garantir sincronização limpa
    rm -rf "$dest"
    cp -r "$src" "$dest"
    log_success "$label: $file_count arquivos copiados"
}

copy_file() {
    local src="$1"
    local dest_dir="$2"
    local dest_name="$3"

    if [ ! -f "$src" ]; then
        log_warn "Arquivo não encontrado, pulando: $src"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[DRY-RUN] $dest_name  ($src)"
        return 0
    fi

    mkdir -p "$dest_dir"
    cp "$src" "$dest_dir/$dest_name"
    log_success "$dest_name"
}

show_stats() {
    echo
    log_info "📊 Estatísticas do dump em: $DUMP_DIR"

    local items=(
        "agents    :$(find "$DUMP_DIR/agents"    -name '*.md'             2>/dev/null | wc -l) agents"
        "commands  :$(find "$DUMP_DIR/commands"  -name '*.md'             2>/dev/null | wc -l) commands"
        "skills    :$(find "$DUMP_DIR/skills"    -name 'CLAUDE.md'        2>/dev/null | wc -l) skills"
        "playbooks :$(find "$DUMP_DIR/playbooks" -name '*.md'             2>/dev/null | wc -l) playbooks"
        "checks    :$(find "$DUMP_DIR/checks"    -name '*.md'             2>/dev/null | wc -l) checks"
        "workflows :$(find "$DUMP_DIR/workflows" -name '*.yaml' -o -name '*.yml' 2>/dev/null | wc -l) workflows"
    )

    for item in "${items[@]}"; do
        local dir="${item%%:*}"
        local count="${item#*:}"
        [ -d "$DUMP_DIR/$dir" ] && echo "    • $dir: $count"
    done

    [ -f "$DUMP_DIR/VERSION" ] && echo "    • Versão: $(cat "$DUMP_DIR/VERSION")"

    local total_size
    total_size=$(du -sh "$DUMP_DIR" 2>/dev/null | cut -f1)
    echo "    • Tamanho total do repositório: $total_size"
}

################################################################################
# Parse de argumentos
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)  DRY_RUN=1 ;;
        --help|-h)  show_help; exit 0 ;;
        *)
            log_error "Argumento desconhecido: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

################################################################################
# Main
################################################################################

echo
echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   dump-ecosystem.sh — Agent-Marcus Ecosystem     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
echo
log_info "Fonte  : $CLAUDE_HOME"
log_info "Destino: $DUMP_DIR"
[ "$DRY_RUN" -eq 1 ] && log_warn "Modo DRY-RUN ativado — nenhum arquivo será modificado"

# Validar fonte
if [ ! -d "$CLAUDE_HOME" ]; then
    log_error "Diretório não encontrado: $CLAUDE_HOME"
    exit 1
fi

# ── Diretórios ────────────────────────────────────────────────────────────────

log_section "Diretórios"

copy_dir "$CLAUDE_HOME/agents"    "$DUMP_DIR/agents"    "agents"
copy_dir "$CLAUDE_HOME/commands"  "$DUMP_DIR/commands"  "commands"
copy_dir "$CLAUDE_HOME/skills"    "$DUMP_DIR/skills"    "skills"
copy_dir "$CLAUDE_HOME/playbooks" "$DUMP_DIR/playbooks" "playbooks"
copy_dir "$CLAUDE_HOME/checks"    "$DUMP_DIR/checks"    "checks"
copy_dir "$CLAUDE_HOME/workflows" "$DUMP_DIR/workflows" "workflows"

# ── Arquivos de documentação ──────────────────────────────────────────────────

log_section "Documentação"

copy_file "$CLAUDE_HOME/CLAUDE.md"  "$DUMP_DIR" "CLAUDE.md"
copy_file "$CLAUDE_HOME/README.md"  "$DUMP_DIR" "README.md"
copy_file "$CLAUDE_HOME/VERSION"    "$DUMP_DIR" "VERSION"

# ANEXOs (I, II, III, IV, V, VI — qualquer quantidade)
for anexo in "$CLAUDE_HOME"/ANEXO*.md; do
    [ -f "$anexo" ] && copy_file "$anexo" "$DUMP_DIR" "$(basename "$anexo")"
done

# Imagens / SVG (se existirem em ~/.claude/img/)
if [ -d "$CLAUDE_HOME/img" ]; then
    copy_dir "$CLAUDE_HOME/img" "$DUMP_DIR/img" "img"
fi

# Scripts de validação
copy_file "$CLAUDE_HOME/validate-ecosystem.sh" "$DUMP_DIR" "validate-ecosystem.sh"
[ -f "$DUMP_DIR/validate-ecosystem.sh" ] && chmod +x "$DUMP_DIR/validate-ecosystem.sh"

if [ -f "$CLAUDE_HOME/skills/skill-helper.sh" ]; then
    copy_file "$CLAUDE_HOME/skills/skill-helper.sh" "$DUMP_DIR/skills" "skill-helper.sh"
    [ -f "$DUMP_DIR/skills/skill-helper.sh" ] && chmod +x "$DUMP_DIR/skills/skill-helper.sh"
fi

# ── Conclusão ─────────────────────────────────────────────────────────────────

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  Dump concluído!                            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"

if [ "$DRY_RUN" -eq 0 ]; then
    show_stats
    echo
    log_info "Próximos passos sugeridos:"
    echo "    1. Revisar as mudanças:  git diff --stat"
    echo "    2. Staگear:              git add -A"
    echo "    3. Commitar:             git commit -m 'chore: dump ecossistema Marcus v\$(cat VERSION)'"
fi

echo
exit 0
