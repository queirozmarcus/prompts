#!/bin/bash
# Skills Helper - Utilitario para gerenciar skills do Codex

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "$SCRIPT_DIR/application-development" ]; then
  SKILLS_DIR="$SCRIPT_DIR"
else
  SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

list_skills() {
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}  📚 Codex Skills${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
  echo ""

  for category in cloud-infrastructure containers-docker application-development devops-cicd operations-monitoring; do
    echo -e "${CYAN}${category}${NC}"
    for skill in "$SKILLS_DIR/$category"/*; do
      [ -d "$skill" ] && echo "  • $(basename "$skill")"
    done
    echo ""
  done
}

find_skill() {
  local skill_name=${1:-}
  find "$SKILLS_DIR" -maxdepth 2 -type d -name "$skill_name" 2>/dev/null | head -1
}

show_skill() {
  local skill=${1:-}
  [ -n "$skill" ] || { echo -e "${YELLOW}Usage: $0 show <skill-name>${NC}"; return 1; }

  local skill_path
  skill_path=$(find_skill "$skill")
  [ -n "$skill_path" ] || { echo -e "${YELLOW}Skill '$skill' not found${NC}"; return 1; }

  if [ -f "$skill_path/SKILL.md" ]; then
    cat "$skill_path/SKILL.md"
  else
    echo -e "${YELLOW}No SKILL.md found for '$skill'${NC}"
    return 1
  fi
}

search_skills() {
  local query=${1:-}
  [ -n "$query" ] || { echo -e "${YELLOW}Usage: $0 search <keyword>${NC}"; return 1; }

  grep -r -i --include="SKILL.md" "$query" "$SKILLS_DIR" 2>/dev/null | while IFS=: read -r file content; do
    local skill category
    skill=$(basename "$(dirname "$file")")
    category=$(basename "$(dirname "$(dirname "$file")")")
    echo -e "${CYAN}[$category]${NC} ${GREEN}$skill:${NC} $content"
  done
}

count_skills() {
  local total
  total=$(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d | wc -l)
  echo -e "${GREEN}Total skills: $total${NC}"
}

validate_skill() {
  local skill=${1:-}
  [ -n "$skill" ] || { echo -e "${YELLOW}Usage: $0 validate <skill-name>${NC}"; return 1; }

  local skill_path file issues=0
  skill_path=$(find_skill "$skill")
  [ -n "$skill_path" ] || { echo -e "${YELLOW}Skill '$skill' not found${NC}"; return 1; }

  file="$skill_path/SKILL.md"
  [ -f "$file" ] || { echo -e "${YELLOW}No SKILL.md found for '$skill'${NC}"; return 1; }

  for section in "## Scope" "## Core Principles" "Communication Style" "Expected Output Quality" "Skill type:"; do
    if grep -q "$section" "$file"; then
      echo -e "${GREEN}✓ Found: ${section}${NC}"
    else
      echo -e "${YELLOW}✗ Missing: ${section}${NC}"
      issues=$((issues + 1))
    fi
  done

  if [ "$issues" -eq 0 ]; then
    echo -e "${GREEN}Skill '$skill' is structurally valid${NC}"
  else
    return 1
  fi
}

usage() {
  cat <<'EOF'
Usage: skill-helper.sh <command> [args]

Commands:
  list
  show <skill-name>
  search <keyword>
  count
  validate <skill-name>
EOF
}

case "${1:-}" in
  list) list_skills ;;
  show) show_skill "${2:-}" ;;
  search) search_skills "${2:-}" ;;
  count) count_skills ;;
  validate) validate_skill "${2:-}" ;;
  *) usage; exit 1 ;;
esac
