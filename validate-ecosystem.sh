#!/usr/bin/env bash
# validate-ecosystem.sh — Validacao completa do ecossistema de agents
# Substitui validate-agents.sh (v5.0.0)
# v1.0.0 — 2026-03-22
set -uo pipefail

# ═══════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════
CLAUDE_DIR="${HOME}/.claude"
AGENTS_DIR="${CLAUDE_DIR}/agents"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
SKILLS_DIR="${CLAUDE_DIR}/skills"
PLAYBOOKS_DIR="${CLAUDE_DIR}/playbooks"
PLUGINS_DIR="${CLAUDE_DIR}/plugins"
CHECKS_DIR="${CLAUDE_DIR}/checks"
WORKFLOWS_DIR="${CLAUDE_DIR}/workflows"
MARCUS_FILE="${AGENTS_DIR}/marcus.md"
CLAUDE_MD="${CLAUDE_DIR}/CLAUDE.md"
REPO_CLAUDE_MD="${AGENTS_DIR}/CLAUDE.md"
VERSION_FILE="${CLAUDE_DIR}/VERSION"

# Ler versão central (fonte única de verdade)
ECOSYSTEM_VERSION=$(cat "${VERSION_FILE}" 2>/dev/null || echo "UNKNOWN")

KNOWN_MODELS="sonnet opus haiku inherit"
KNOWN_TOOLS="Read Write Edit Grep Glob Bash Task Agent WebFetch WebSearch NotebookEdit"
AGENT_REQUIRED_FIELDS="name description tools model version"
COMMAND_REQUIRED_FIELDS="name description"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
INFO_COUNT=0
FIX_COUNT=0
VERBOSE=false
FIX_MODE=false
SECTION=""

# ═══════════════════════════════════════════════════════════════
# COLORS & HELPERS
# ═══════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

pass()  { PASS_COUNT=$((PASS_COUNT + 1)); if $VERBOSE; then echo -e "  ${GREEN}[PASS]${NC} $1"; fi; }
warn()  { WARN_COUNT=$((WARN_COUNT + 1)); echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail()  { FAIL_COUNT=$((FAIL_COUNT + 1)); echo -e "  ${RED}[FAIL]${NC} $1"; }
info()  { INFO_COUNT=$((INFO_COUNT + 1)); if $VERBOSE; then echo -e "  ${BLUE}[INFO]${NC} $1"; fi; }
fixed() { FIX_COUNT=$((FIX_COUNT + 1));   echo -e "  ${CYAN}[FIX ]${NC} $1"; }

section_header() {
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
}

# Extrai campo do frontmatter YAML de um arquivo markdown
# Uso: extract_field <file> <field>
extract_field() {
    local file="$1" field="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep -m1 "^${field}:" | sed "s/^${field}:\s*//" | sed 's/^"\(.*\)"$/\1/' | xargs 2>/dev/null || echo ""
}

# Verifica se arquivo tem frontmatter valido
has_frontmatter() {
    local file="$1"
    head -1 "$file" | grep -q "^---$" && sed -n '2,/^---$/p' "$file" | tail -1 | grep -q "^---$"
}

# Extrai todos os nomes de agents referenciados no corpo de um arquivo
# Busca padroes como: **agent-name**, sub-agente **name**, `agent-name`
extract_referenced_agents() {
    local file="$1"
    # Pega conteudo apos o segundo ---
    sed -n '/^---$/,/^---$/!p' "$file" | \
        grep -oP '(?:sub-agente |sub-agent |agente |Use o )\*\*\K[a-z][a-z0-9-]+(?=\*\*)' | \
        sort -u
}

# Lista todos os agent names instalados
get_installed_agents() {
    for f in "${AGENTS_DIR}"/*.md; do
        [[ "$(basename "$f")" == "CLAUDE.md" ]] && continue
        [[ "$(basename "$f")" == "README.md" ]] && continue
        extract_field "$f" "name"
    done | sort -u
}

# Lista todos os command names instalados
get_installed_commands() {
    for f in "${COMMANDS_DIR}"/*.md; do
        basename "$f" .md
    done | sort -u
}

# ═══════════════════════════════════════════════════════════════
# MODULE 1: VALIDATE AGENTS
# ═══════════════════════════════════════════════════════════════
validate_agents() {
    section_header "Module 1: Agents"
    local agent_count=0
    local names_seen=()

    for agent_file in "${AGENTS_DIR}"/*.md; do
        local filename
        filename="$(basename "$agent_file" .md)"

        # Pula CLAUDE.md e README.md
        [[ "$filename" == "CLAUDE" || "$filename" == "README" ]] && continue

        agent_count=$((agent_count + 1))

        # Frontmatter existe
        if ! has_frontmatter "$agent_file"; then
            fail "${filename}: frontmatter ausente ou invalido"
            continue
        fi
        pass "${filename}: frontmatter valido"

        # Campos obrigatorios
        for field in $AGENT_REQUIRED_FIELDS; do
            local value
            value="$(extract_field "$agent_file" "$field")"
            if [[ -z "$value" ]]; then
                fail "${filename}: campo obrigatorio '${field}' ausente"
            else
                pass "${filename}: campo '${field}' presente"
            fi
        done

        # Name bate com filename
        local name_value
        name_value="$(extract_field "$agent_file" "name")"
        if [[ -n "$name_value" && "$name_value" != "$filename" ]]; then
            fail "${filename}: name '${name_value}' nao bate com filename '${filename}'"
        elif [[ -n "$name_value" ]]; then
            pass "${filename}: name bate com filename"
        fi

        # Model valido
        local model_value
        model_value="$(extract_field "$agent_file" "model")"
        if [[ -n "$model_value" ]]; then
            if echo "$KNOWN_MODELS" | grep -qw "$model_value"; then
                pass "${filename}: model '${model_value}' valido"
            else
                warn "${filename}: model '${model_value}' nao reconhecido (esperado: ${KNOWN_MODELS})"
            fi
        fi

        # Tools conhecidas
        local tools_value
        tools_value="$(extract_field "$agent_file" "tools")"
        if [[ -n "$tools_value" ]]; then
            IFS=',' read -ra tools_arr <<< "$tools_value"
            for tool in "${tools_arr[@]}"; do
                tool="$(echo "$tool" | xargs)"
                # MCP tools sao permitidas (prefixo mcp__)
                if [[ "$tool" == mcp__* ]]; then
                    pass "${filename}: tool MCP '${tool}'"
                elif echo "$KNOWN_TOOLS" | grep -qw "$tool"; then
                    pass "${filename}: tool '${tool}' conhecida"
                else
                    warn "${filename}: tool '${tool}' nao reconhecida"
                fi
            done
        fi

        # Colisao de nomes
        if printf '%s\n' "${names_seen[@]}" 2>/dev/null | grep -qx "$name_value"; then
            fail "${filename}: nome '${name_value}' duplicado (colisao)"
        else
            names_seen+=("$name_value")
        fi
    done

    # Junk files
    for junk in "${AGENTS_DIR}"/*Zone.Identifier "${AGENTS_DIR}"/*~ "${AGENTS_DIR}"/*.bak; do
        [[ -e "$junk" ]] || continue
        if $FIX_MODE; then
            rm -f "$junk"
            fixed "removido junk file: $(basename "$junk")"
        else
            warn "junk file encontrado: $(basename "$junk") (use --fix para remover)"
        fi
    done

    # Versao uniforme (comparada com VERSION file)
    if [[ "$ECOSYSTEM_VERSION" != "UNKNOWN" ]]; then
        # Validar documentação (6 arquivos)
        local docs=(
            "CLAUDE.md"
            "README.md"
            "ANEXOII-ARQUITETURA.md"
            "ANEXOIV-AGENT-CAPABILITIES.md"
            "ANEXOV-MANUAL-VALIDACAO-ECO.md"
            "ANEXOVI-Modelos-por-Perfil-de-Agent.md"
        )
        for doc in "${docs[@]}"; do
            local doc_path="${CLAUDE_DIR}/${doc}"
            if [[ -f "$doc_path" ]]; then
                if ! grep -q "v${ECOSYSTEM_VERSION}" "$doc_path"; then
                    warn "Documentation ${doc}: version v${ECOSYSTEM_VERSION} not found"
                else
                    pass "Documentation ${doc}: version v${ECOSYSTEM_VERSION} found"
                fi
            fi
        done

        # Validar agents
        for agent_file in "${AGENTS_DIR}"/*.md; do
            local fn
            fn="$(basename "$agent_file" .md)"
            [[ "$fn" == "CLAUDE" || "$fn" == "README" ]] && continue
            local av
            av="$(extract_field "$agent_file" "version")"
            if [[ -n "$av" && "$av" != "$ECOSYSTEM_VERSION" ]]; then
                warn "${fn}: version '${av}' differs from ecosystem '${ECOSYSTEM_VERSION}'"
            fi
        done
    else
        warn "VERSION file not found at ${VERSION_FILE}"
    fi

    info "Total agents encontrados: ${agent_count}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 2: VALIDATE COMMANDS
# ═══════════════════════════════════════════════════════════════
validate_commands() {
    section_header "Module 2: Commands"
    local cmd_count=0

    # Diretorio de commands do repo (busca em pack structure E flat structure)
    local repo_commands=()
    # Pack structure: teams-agents-*/.claude/commands/
    while IFS= read -r -d '' f; do
        repo_commands+=("$(basename "$f" .md)")
    done < <(find "${AGENTS_DIR}/teams-agents-"*"/.claude/commands" -name "*.md" -print0 2>/dev/null)
    # Flat repo structure: ~/iGitHub/claude-code-agents/commands/
    local repo_flat="${HOME}/iGitHub/claude-code-agents/commands"
    if [[ -d "$repo_flat" ]]; then
        while IFS= read -r -d '' f; do
            local bn
            bn="$(basename "$f" .md)"
            if ! printf '%s\n' "${repo_commands[@]}" 2>/dev/null | grep -qx "$bn"; then
                repo_commands+=("$bn")
            fi
        done < <(find "$repo_flat" -name "*.md" -print0 2>/dev/null)
    fi

    # Pre-computa lista de agents instalados (uma vez, fora do loop)
    local installed_agents
    installed_agents="$(get_installed_agents)"

    for cmd_file in "${COMMANDS_DIR}"/*.md; do
        local filename
        filename="$(basename "$cmd_file" .md)"
        cmd_count=$((cmd_count + 1))

        # Frontmatter existe
        if ! has_frontmatter "$cmd_file"; then
            fail "${filename}: frontmatter ausente"
            continue
        fi
        pass "${filename}: frontmatter valido"

        # Campos obrigatorios
        for field in $COMMAND_REQUIRED_FIELDS; do
            local value
            value="$(extract_field "$cmd_file" "$field")"
            if [[ -z "$value" ]]; then
                fail "${filename}: campo '${field}' ausente"
            else
                pass "${filename}: campo '${field}' presente"
            fi
        done

        # Name bate com filename
        local name_value
        name_value="$(extract_field "$cmd_file" "name")"
        if [[ -n "$name_value" && "$name_value" != "$filename" ]]; then
            fail "${filename}: name '${name_value}' nao bate com filename"
        elif [[ -n "$name_value" ]]; then
            pass "${filename}: name bate com filename"
        fi

        # Agents referenciados existem
        local referenced_agents
        referenced_agents="$(extract_referenced_agents "$cmd_file")"
        if [[ -n "$referenced_agents" ]]; then
            while IFS= read -r agent; do
                if echo "$installed_agents" | grep -qx "$agent"; then
                    pass "${filename}: agent referenciado '${agent}' existe"
                else
                    fail "${filename}: agent referenciado '${agent}' NAO encontrado em agents/"
                fi
            done <<< "$referenced_agents"
        fi

        # Tem source no repo
        if printf '%s\n' "${repo_commands[@]}" 2>/dev/null | grep -qx "$filename"; then
            pass "${filename}: tem source no repo"
        else
            warn "${filename}: instalado sem source no repo (comando fantasma)"
        fi

        # argument-hint presente
        local hint
        hint="$(extract_field "$cmd_file" "argument-hint")"
        if [[ -n "$hint" ]]; then
            pass "${filename}: argument-hint presente"
        else
            warn "${filename}: argument-hint ausente (recomendado)"
        fi
    done

    info "Total commands encontrados: ${cmd_count}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 3: VALIDATE SKILLS
# ═══════════════════════════════════════════════════════════════
validate_skills() {
    section_header "Module 3: Skills"
    local skill_count=0
    local required_sections=("## Scope" "## Core Principles" "Communication Style" "Expected Output Quality" "Skill type:")

    # Skills estao em subdiretorios: skills/<category>/<name>/CLAUDE.md
    while IFS= read -r -d '' skill_file; do
        local skill_path
        skill_path="$(dirname "$skill_file")"
        local skill_name
        skill_name="$(basename "$skill_path")"
        local category
        category="$(basename "$(dirname "$skill_path")")"
        local display="${category}/${skill_name}"
        skill_count=$((skill_count + 1))

        # Arquivo nao vazio
        if [[ ! -s "$skill_file" ]]; then
            fail "${display}: arquivo CLAUDE.md vazio"
            continue
        fi
        pass "${display}: arquivo nao vazio"

        # Secoes obrigatorias
        for section in "${required_sections[@]}"; do
            if grep -q "$section" "$skill_file"; then
                pass "${display}: secao '${section}' presente"
            else
                fail "${display}: secao '${section}' ausente"
            fi
        done

        # Conteudo minimo
        local line_count
        line_count="$(wc -l < "$skill_file")"
        if [[ "$line_count" -lt 50 ]]; then
            warn "${display}: apenas ${line_count} linhas (minimo recomendado: 50)"
        else
            pass "${display}: ${line_count} linhas (adequado)"
        fi
    done < <(find "$SKILLS_DIR" -name "CLAUDE.md" -print0 2>/dev/null)

    info "Total skills encontradas: ${skill_count}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 4: VALIDATE PLAYBOOKS
# ═══════════════════════════════════════════════════════════════
validate_playbooks() {
    section_header "Module 4: Playbooks"
    local pb_count=0
    local installed_commands
    installed_commands="$(get_installed_commands)"
    local installed_agents
    installed_agents="$(get_installed_agents)"

    for pb_file in "${PLAYBOOKS_DIR}"/*.md; do
        [[ -e "$pb_file" ]] || continue
        local filename
        filename="$(basename "$pb_file" .md)"
        pb_count=$((pb_count + 1))

        # Nao vazio
        if [[ ! -s "$pb_file" ]]; then
            fail "${filename}: arquivo vazio"
            continue
        fi
        pass "${filename}: arquivo nao vazio"

        # Commands referenciados existem
        local referenced_cmds
        referenced_cmds="$(grep -oP '(?<=/)[\w-]+' "$pb_file" | sort -u)"
        if [[ -n "$referenced_cmds" ]]; then
            while IFS= read -r cmd; do
                # Filtra falsos positivos (paths como api/v1, etc)
                if echo "$installed_commands" | grep -qx "$cmd"; then
                    pass "${filename}: command '/${cmd}' existe"
                fi
            done <<< "$referenced_cmds"
        fi

        # Checks referenciados existem
        local referenced_checks
        referenced_checks="$(grep -oP 'checks/[\w-]+\.md' "$pb_file" 2>/dev/null | sort -u)"
        if [[ -n "$referenced_checks" ]]; then
            while IFS= read -r check; do
                if [[ -f "${CLAUDE_DIR}/${check}" ]]; then
                    pass "${filename}: check '${check}' existe"
                else
                    warn "${filename}: check '${check}' referenciado mas nao encontrado"
                fi
            done <<< "$referenced_checks"
        fi
    done

    info "Total playbooks encontrados: ${pb_count}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 5: VALIDATE PLUGINS
# ═══════════════════════════════════════════════════════════════
validate_plugins() {
    section_header "Module 5: Plugins"

    # Lista plugins instalados (diretorios em plugins/cache ou plugins/installed)
    local installed_plugins=()
    if [[ -d "${PLUGINS_DIR}" ]]; then
        # Busca em settings.json ou na estrutura de cache
        while IFS= read -r plugin_dir; do
            local pname
            pname="$(basename "$plugin_dir")"
            [[ "$pname" == "cache" || "$pname" == "." ]] && continue
            [[ "$pname" == "marketplaces" ]] && continue
            [[ "$pname" == temp_* ]] && continue
            [[ "$pname" == "context-mode" ]] && continue
            [[ "$pname" == "claude-plugins-official" ]] && continue
            [[ "$pname" == "superpowers-marketplace" ]] && continue
            installed_plugins+=("$pname")
            info "Plugin instalado: ${pname}"
        done < <(find "${PLUGINS_DIR}" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)

        # Tambem verifica plugins no cache (ignora dirs temporarios e internos)
        if [[ -d "${PLUGINS_DIR}/cache" ]]; then
            while IFS= read -r plugin_dir; do
                local pname
                pname="$(basename "$plugin_dir")"
                # Ignora dirs temporarios, marketplaces, e internos do plugin system
                [[ "$pname" == temp_* ]] && continue
                [[ "$pname" == "marketplaces" ]] && continue
                [[ "$pname" == "context-mode" ]] && continue
                [[ "$pname" == "claude-plugins-official" ]] && continue
                [[ "$pname" == "superpowers-marketplace" ]] && continue
                if ! printf '%s\n' "${installed_plugins[@]}" 2>/dev/null | grep -qx "$pname"; then
                    installed_plugins+=("$pname")
                    info "Plugin em cache: ${pname}"
                fi
            done < <(find "${PLUGINS_DIR}/cache" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
        fi
    fi

    # Verifica se Marcus documenta os plugins
    if [[ -f "$MARCUS_FILE" ]]; then
        for plugin in "${installed_plugins[@]}"; do
            # Normaliza nome para busca (ex: claude-plugins-official -> superpowers)
            # Plugins podem ter nomes de diretorio diferentes do nome logico
            if grep -qi "$plugin" "$MARCUS_FILE" 2>/dev/null; then
                pass "Plugin '${plugin}' documentado no marcus.md"
            else
                warn "Plugin '${plugin}' instalado mas nao encontrado no marcus.md"
            fi
        done
    fi

    # Verifica se CLAUDE.md global lista plugins
    if [[ -f "$CLAUDE_MD" ]]; then
        for plugin in "${installed_plugins[@]}"; do
            if grep -qi "$plugin" "$CLAUDE_MD" 2>/dev/null; then
                pass "Plugin '${plugin}' documentado no CLAUDE.md global"
            else
                warn "Plugin '${plugin}' instalado mas nao encontrado no CLAUDE.md global"
            fi
        done
    fi

    info "Total plugins encontrados: ${#installed_plugins[@]}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 6: VALIDATE CROSS-REFERENCES
# ═══════════════════════════════════════════════════════════════
validate_crossrefs() {
    section_header "Module 6: Cross-References"
    local installed_commands
    installed_commands="$(get_installed_commands)"
    local installed_agents
    installed_agents="$(get_installed_agents)"

    # 6.1 — Marcus cataloga todos os commands
    echo -e "  ${DIM}Checking: Marcus cataloga todos os commands${NC}"
    while IFS= read -r cmd; do
        if grep -q "/${cmd}" "$MARCUS_FILE" 2>/dev/null; then
            pass "Command '/${cmd}' catalogado no marcus.md"
        else
            fail "Command '/${cmd}' existe mas NAO catalogado no marcus.md"
        fi
    done <<< "$installed_commands"

    # 6.2 — Marcus lista todos os agents no ecossistema
    echo -e "  ${DIM}Checking: Marcus lista todos os agents${NC}"
    while IFS= read -r agent; do
        [[ "$agent" == "marcus" ]] && continue
        if grep -q "$agent" "$MARCUS_FILE" 2>/dev/null; then
            pass "Agent '${agent}' listado no marcus.md"
        else
            fail "Agent '${agent}' existe mas NAO listado no marcus.md"
        fi
    done <<< "$installed_agents"

    # 6.3 — Contagens numericas coerentes
    echo -e "  ${DIM}Checking: Contagens numericas${NC}"
    local actual_agents actual_commands actual_playbooks
    actual_agents="$(echo "$installed_agents" | wc -l)"
    actual_commands="$(echo "$installed_commands" | wc -l)"
    actual_playbooks="$(find "$PLAYBOOKS_DIR" -name "*.md" 2>/dev/null | wc -l)"
    local actual_skills
    actual_skills="$(find "$SKILLS_DIR" -name "CLAUDE.md" 2>/dev/null | wc -l)"

    # Extrai contagens do CLAUDE.md global (linha de resumo)
    if [[ -f "$CLAUDE_MD" ]]; then
        local summary_line
        summary_line="$(grep -oP '\d+ agents' "$CLAUDE_MD" | head -1)"
        local expected_agents
        expected_agents="$(echo "$summary_line" | grep -oP '^\d+')"
        if [[ -n "$expected_agents" ]]; then
            if [[ "$actual_agents" -eq "$expected_agents" ]]; then
                pass "Agent count: ${actual_agents} (matches CLAUDE.md: ${expected_agents})"
            else
                fail "Agent count mismatch: real=${actual_agents}, CLAUDE.md=${expected_agents}"
            fi
        fi

        local expected_commands
        expected_commands="$(grep -oP '\d+ pack commands' "$CLAUDE_MD" | head -1 | grep -oP '^\d+')"
        if [[ -n "$expected_commands" ]]; then
            if [[ "$actual_commands" -eq "$expected_commands" ]]; then
                pass "Command count: ${actual_commands} (matches CLAUDE.md: ${expected_commands})"
            else
                fail "Command count mismatch: real=${actual_commands}, CLAUDE.md=${expected_commands}"
            fi
        fi
    fi

    # Extrai contagens do marcus.md
    if [[ -f "$MARCUS_FILE" ]]; then
        local marcus_playbook_count
        marcus_playbook_count="$(grep -oP '\d+ playbooks' "$MARCUS_FILE" | head -1 | grep -oP '^\d+')"
        if [[ -n "$marcus_playbook_count" ]]; then
            if [[ "$actual_playbooks" -eq "$marcus_playbook_count" ]]; then
                pass "Playbook count: ${actual_playbooks} (matches marcus.md: ${marcus_playbook_count})"
            else
                fail "Playbook count mismatch: real=${actual_playbooks}, marcus.md=${marcus_playbook_count}"
            fi
        fi
    fi

    # 6.4 — Skill names no marcus.md usam nomes completos do superpowers
    echo -e "  ${DIM}Checking: Skill names corretos${NC}"
    local bad_skill_names=("tdd" "debugging" "code-review" "execute-plans" "git-worktrees")
    local good_skill_names=("test-driven-development" "systematic-debugging" "requesting-code-review" "executing-plans" "using-git-worktrees")
    for i in "${!bad_skill_names[@]}"; do
        local bad="${bad_skill_names[$i]}"
        local good="${good_skill_names[$i]}"
        # Busca o nome abreviado como palavra isolada (backtick-delimitado)
        if grep -qP "\`${bad}\`" "$MARCUS_FILE" 2>/dev/null; then
            warn "marcus.md usa nome abreviado '${bad}' em vez de '${good}'"
        fi
        if [[ -f "$CLAUDE_MD" ]] && grep -qP "\`${bad}\`" "$CLAUDE_MD" 2>/dev/null; then
            warn "CLAUDE.md usa nome abreviado '${bad}' em vez de '${good}'"
        fi
    done

    # 6.5 — Delegation chains no marcus.md referenciam agents existentes
    echo -e "  ${DIM}Checking: Delegation chains${NC}"
    local chains
    chains="$(grep -oP '(?<=\| )[\w-]+(?: → [\w-]+)+' "$MARCUS_FILE" 2>/dev/null | sort -u)"
    if [[ -n "$chains" ]]; then
        while IFS= read -r chain; do
            IFS=' → ' read -ra agents_in_chain <<< "$(echo "$chain" | sed 's/ → / /g')"
            for agent in "${agents_in_chain[@]}"; do
                agent="$(echo "$agent" | xargs)"
                [[ -z "$agent" || "$agent" == "→" ]] && continue
                # Trata "ALL" como keyword valida
                [[ "$agent" == "ALL" ]] && continue
                if echo "$installed_agents" | grep -qx "$agent"; then
                    pass "Chain agent '${agent}' existe"
                else
                    # Pode ser keyword (ex: "packs"), nao necessariamente agent
                    if [[ "$agent" =~ ^[a-z][a-z0-9-]+$ ]]; then
                        warn "Chain agent '${agent}' nao encontrado como agent instalado"
                    fi
                fi
            done
        done <<< "$chains"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MODULE 7: VALIDATE INVENTORY
# ═══════════════════════════════════════════════════════════════
validate_inventory() {
    section_header "Module 7: Inventory"

    local actual_agents actual_commands actual_skills actual_playbooks actual_checks actual_workflows
    actual_agents="$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" ! -name "CLAUDE.md" ! -name "README.md" | wc -l)"
    actual_commands="$(find "$COMMANDS_DIR" -name "*.md" 2>/dev/null | wc -l)"
    actual_skills="$(find "$SKILLS_DIR" -name "CLAUDE.md" 2>/dev/null | wc -l)"
    actual_playbooks="$(find "$PLAYBOOKS_DIR" -name "*.md" 2>/dev/null | wc -l)"
    actual_checks="$(find "$CHECKS_DIR" -name "*.md" 2>/dev/null | wc -l)"
    actual_workflows="$(find "$WORKFLOWS_DIR" -name "*.workflow.yaml" 2>/dev/null | wc -l)"

    # Plugins (conta a partir do installed_plugins.json)
    local actual_plugins=0
    local plugins_json="${PLUGINS_DIR}/installed_plugins.json"
    if [[ -f "$plugins_json" ]]; then
        actual_plugins="$(grep -c '"scope":' "$plugins_json" 2>/dev/null || echo 0)"
    elif [[ -d "${PLUGINS_DIR}/cache" ]]; then
        actual_plugins="$(find "${PLUGINS_DIR}/cache" -maxdepth 2 -mindepth 2 -type d ! -path "*/temp_*" 2>/dev/null | wc -l)"
    fi

    # Commands sem source no repo (busca pack + flat)
    local phantom_count=0
    local repo_commands=()
    while IFS= read -r -d '' f; do
        repo_commands+=("$(basename "$f" .md)")
    done < <(find "${AGENTS_DIR}/teams-agents-"*"/.claude/commands" -name "*.md" -print0 2>/dev/null)
    local repo_flat="${HOME}/iGitHub/claude-code-agents/commands"
    if [[ -d "$repo_flat" ]]; then
        while IFS= read -r -d '' f; do
            local bn
            bn="$(basename "$f" .md)"
            if ! printf '%s\n' "${repo_commands[@]}" 2>/dev/null | grep -qx "$bn"; then
                repo_commands+=("$bn")
            fi
        done < <(find "$repo_flat" -name "*.md" -print0 2>/dev/null)
    fi

    for cmd_file in "${COMMANDS_DIR}"/*.md; do
        local fn
        fn="$(basename "$cmd_file" .md)"
        if ! printf '%s\n' "${repo_commands[@]}" 2>/dev/null | grep -qx "$fn"; then
            phantom_count=$((phantom_count + 1))
        fi
    done

    echo ""
    echo -e "  ${BOLD}Agents:${NC}      ${actual_agents}"
    echo -e "  ${BOLD}Commands:${NC}    ${actual_commands}  ${DIM}(${phantom_count} sem source no repo)${NC}"
    echo -e "  ${BOLD}Skills:${NC}      ${actual_skills}"
    echo -e "  ${BOLD}Playbooks:${NC}   ${actual_playbooks}"
    echo -e "  ${BOLD}Checks:${NC}      ${actual_checks}"
    echo -e "  ${BOLD}Workflows:${NC}   ${actual_workflows}"
    echo -e "  ${BOLD}Plugins:${NC}     ${actual_plugins}"
}

# ═══════════════════════════════════════════════════════════════
# MODULE 8: VALIDATE WORKFLOWS
# ═══════════════════════════════════════════════════════════════
validate_workflows() {
    section_header "Module 8: Workflows"
    local wf_count=0

    if [[ ! -d "$WORKFLOWS_DIR" ]]; then
        info "Diretorio workflows/ nao encontrado — pulando"
        return
    fi

    local installed_agents
    installed_agents="$(get_installed_agents)"

    for wf_file in "${WORKFLOWS_DIR}"/*.workflow.yaml; do
        [[ -e "$wf_file" ]] || continue
        local filename
        filename="$(basename "$wf_file")"
        wf_count=$((wf_count + 1))

        # YAML valido (usa python3 se disponivel, senao basico)
        if command -v python3 &>/dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('${wf_file}'))" 2>/dev/null; then
                pass "${filename}: YAML valido"
            else
                fail "${filename}: YAML invalido (parse error)"
                continue
            fi
        else
            # Fallback: verifica se comeca com 'workflow:' (check basico)
            if grep -q "^workflow:" "$wf_file"; then
                pass "${filename}: estrutura basica presente"
            else
                fail "${filename}: nao comeca com 'workflow:'"
                continue
            fi
        fi

        # Campos obrigatorios do workflow
        for field in name description version; do
            if grep -q "  ${field}:" "$wf_file"; then
                pass "${filename}: campo '${field}' presente"
            else
                fail "${filename}: campo obrigatorio '${field}' ausente"
            fi
        done

        # Steps existem
        if grep -q "  steps:" "$wf_file"; then
            pass "${filename}: secao 'steps' presente"
        else
            fail "${filename}: secao 'steps' ausente"
            continue
        fi

        # Step IDs unicos
        local step_ids
        step_ids="$(grep -oP '^\s+- id:\s*\K\S+' "$wf_file" | sort)"
        local unique_ids
        unique_ids="$(echo "$step_ids" | sort -u)"
        if [[ "$step_ids" == "$unique_ids" ]]; then
            pass "${filename}: step IDs unicos"
        else
            local dupes
            dupes="$(echo "$step_ids" | sort | uniq -d | tr '\n' ', ')"
            fail "${filename}: step IDs duplicados: ${dupes}"
        fi

        # Agents referenciados existem
        local referenced_agents
        referenced_agents="$(grep -oP '^\s+agent:\s*\K\S+' "$wf_file" | sort -u)"
        if [[ -n "$referenced_agents" ]]; then
            while IFS= read -r agent; do
                if echo "$installed_agents" | grep -qx "$agent"; then
                    pass "${filename}: agent '${agent}' existe"
                else
                    fail "${filename}: agent '${agent}' NAO encontrado em agents/"
                fi
            done <<< "$referenced_agents"
        fi

        # Checks referenciados existem
        local referenced_checks
        referenced_checks="$(grep -oP 'check_ref:\s*\K\S+' "$wf_file" | sort -u)"
        if [[ -n "$referenced_checks" ]]; then
            while IFS= read -r check; do
                if [[ -f "${CHECKS_DIR}/${check}.md" ]]; then
                    pass "${filename}: check '${check}' existe"
                else
                    fail "${filename}: check '${check}' NAO encontrado em checks/"
                fi
            done <<< "$referenced_checks"
        fi

        # depends_on sem ciclos (verificacao basica: step nao depende de si mesmo)
        local deps_lines
        deps_lines="$(grep -B1 'depends_on:' "$wf_file" 2>/dev/null)"
        if [[ -n "$deps_lines" ]]; then
            # Extrai pares id -> dep e verifica self-reference
            while IFS= read -r step_id; do
                local deps_for_step
                deps_for_step="$(grep -A1 "id: ${step_id}" "$wf_file" | grep 'depends_on' | grep -oP '\[.*\]')"
                if echo "$deps_for_step" | grep -q "$step_id"; then
                    fail "${filename}: step '${step_id}' depende de si mesmo (ciclo)"
                fi
            done <<< "$step_ids"
            pass "${filename}: sem self-references em depends_on"
        fi

        # Params obrigatorios tem required: true
        local required_params
        required_params="$(grep -c 'required: true' "$wf_file" 2>/dev/null || echo 0)"
        if [[ "$required_params" -gt 0 ]]; then
            pass "${filename}: ${required_params} param(s) obrigatorio(s) declarado(s)"
        else
            warn "${filename}: nenhum param obrigatorio declarado"
        fi
    done

    # README existe
    if [[ -f "${WORKFLOWS_DIR}/README.md" ]]; then
        pass "workflows/README.md presente"
    else
        warn "workflows/README.md ausente (recomendado)"
    fi

    info "Total workflows encontrados: ${wf_count}"
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Validacao completa do ecossistema de agents Claude Code."
    echo ""
    echo "Options:"
    echo "  --section <name>   Roda apenas uma secao"
    echo "                     (agents|commands|skills|playbooks|plugins|crossrefs|inventory|workflows)"
    echo "  --verbose          Mostra detalhes de cada check (inclusive PASS)"
    echo "  --fix              Auto-fix quando possivel (ex: remover junk files)"
    echo "  --help             Mostra esta mensagem"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")                    # Roda tudo"
    echo "  $(basename "$0") --verbose          # Roda tudo com detalhes"
    echo "  $(basename "$0") --section agents   # Valida apenas agents"
    echo "  $(basename "$0") --fix              # Roda tudo e corrige junk files"
}

main() {
    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose) VERBOSE=true; shift ;;
            --fix) FIX_MODE=true; shift ;;
            --section) SECTION="$2"; shift 2 ;;
            --help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done

    echo ""
    echo -e "${BOLD}${CYAN}  ECOSYSTEM VALIDATOR v1.0.0${NC}"
    echo -e "${DIM}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"

    # Pre-flight checks
    if [[ ! -d "$AGENTS_DIR" ]]; then
        echo -e "${RED}FATAL: Diretorio de agents nao encontrado: ${AGENTS_DIR}${NC}"
        exit 2
    fi

    # Run modules
    if [[ -z "$SECTION" || "$SECTION" == "agents" ]]; then
        validate_agents
    fi
    if [[ -z "$SECTION" || "$SECTION" == "commands" ]]; then
        validate_commands
    fi
    if [[ -z "$SECTION" || "$SECTION" == "skills" ]]; then
        validate_skills
    fi
    if [[ -z "$SECTION" || "$SECTION" == "playbooks" ]]; then
        validate_playbooks
    fi
    if [[ -z "$SECTION" || "$SECTION" == "plugins" ]]; then
        validate_plugins
    fi
    if [[ -z "$SECTION" || "$SECTION" == "crossrefs" ]]; then
        validate_crossrefs
    fi
    if [[ -z "$SECTION" || "$SECTION" == "workflows" ]]; then
        validate_workflows
    fi
    if [[ -z "$SECTION" || "$SECTION" == "inventory" ]]; then
        validate_inventory
    fi

    # Summary
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  RESULTS${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}PASS:${NC}  ${PASS_COUNT}"
    echo -e "  ${YELLOW}WARN:${NC}  ${WARN_COUNT}"
    echo -e "  ${RED}FAIL:${NC}  ${FAIL_COUNT}"
    [[ $FIX_COUNT -gt 0 ]] && echo -e "  ${CYAN}FIX:${NC}   ${FIX_COUNT}"
    [[ $INFO_COUNT -gt 0 ]] && $VERBOSE && echo -e "  ${BLUE}INFO:${NC}  ${INFO_COUNT}"
    echo -e "${BOLD}══════════════════════════════════════════════════${NC}"

    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo -e "  ${RED}${BOLD}Ecosystem has ${FAIL_COUNT} failure(s).${NC}"
        exit 1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}Ecosystem OK with ${WARN_COUNT} warning(s).${NC}"
        exit 0
    else
        echo -e "  ${GREEN}${BOLD}Ecosystem is healthy.${NC}"
        exit 0
    fi
}

main "$@"
