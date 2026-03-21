#!/bin/bash
# Skills Helper - Utilitário para gerenciar Gemini CLI skills

SKILLS_DIR="$HOME/.gemini/skills"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to list all skills
list_skills() {
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  📚 Gemini CLI Skills${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}☁️  Cloud & Infrastructure${NC} ${MAGENTA}(cloud-infrastructure/)${NC}"
    for skill in "$SKILLS_DIR/cloud-infrastructure"/*; do
        [ -d "$skill" ] && echo "    • $(basename "$skill")"
    done
    echo ""

    echo -e "${CYAN}🐳 Containers & Docker${NC} ${MAGENTA}(containers-docker/)${NC}"
    for skill in "$SKILLS_DIR/containers-docker"/*; do
        [ -d "$skill" ] && echo "    • $(basename "$skill")"
    done
    echo ""

    echo -e "${CYAN}💻 Application Development${NC} ${MAGENTA}(application-development/)${NC}"
    for skill in "$SKILLS_DIR/application-development"/*; do
        [ -d "$skill" ] && echo "    • $(basename "$skill")"
    done
    echo ""

    echo -e "${CYAN}🔧 DevOps & CI/CD${NC} ${MAGENTA}(devops-cicd/)${NC}"
    for skill in "$SKILLS_DIR/devops-cicd"/*; do
        [ -d "$skill" ] && echo "    • $(basename "$skill")"
    done
    echo ""

    echo -e "${CYAN}🔒 Operations & Monitoring${NC} ${MAGENTA}(operations-monitoring/)${NC}"
    for skill in "$SKILLS_DIR/operations-monitoring"/*; do
        [ -d "$skill" ] && echo "    • $(basename "$skill")"
    done
    echo ""
}

# Function to find a skill across all categories
find_skill() {
    local skill_name=$1
    find "$SKILLS_DIR" -maxdepth 2 -type d -name "$skill_name" 2>/dev/null | head -1
}

# Function to show a specific skill
show_skill() {
    local skill=$1
    if [ -z "$skill" ]; then
        echo -e "${YELLOW}Usage: $0 show <skill-name>${NC}"
        return 1
    fi

    local skill_path=$(find_skill "$skill")

    if [ -z "$skill_path" ]; then
        echo -e "${YELLOW}Skill '$skill' not found${NC}"
        echo -e "${YELLOW}Use '$0 list' to see available skills${NC}"
        return 1
    fi

    local category=$(basename "$(dirname "$skill_path")")

    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  📄 Skill: $skill${NC}"
    echo -e "${CYAN}  Category: $category${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    if [ -f "$skill_path/GEMINI.md" ]; then
        cat "$skill_path/GEMINI.md"
    elif [ -f "$skill_path/CLAUDE.md" ]; then
        cat "$skill_path/CLAUDE.md"
    else
        echo -e "${YELLOW}No GEMINI.md or CLAUDE.md found for this skill${NC}"
    fi
}

# Function to search skills
search_skills() {
    local query=$1
    if [ -z "$query" ]; then
        echo -e "${YELLOW}Usage: $0 search <keyword>${NC}"
        return 1
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🔍 Searching for: $query${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    # Search in both GEMINI.md and CLAUDE.md
    grep -r -i --include="GEMINI.md" --include="CLAUDE.md" "$query" "$SKILLS_DIR" 2>/dev/null | while IFS=: read -r file content; do
        skill=$(basename "$(dirname "$file")")
        category=$(basename "$(dirname "$(dirname "$file")")")
        filename=$(basename "$file")
        echo -e "${CYAN}[$category]${NC} ${GREEN}$skill ($filename):${NC} $content"
    done
}

# Function to count skills
count_skills() {
    local total=0
    for category in "$SKILLS_DIR"/*; do
        if [ -d "$category" ] && [ "$(basename "$category")" != "README.md" ] && [ "$(basename "$category")" != "skill-helper.sh" ]; then
            count=$(find "$category" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
            total=$((total + count))
        fi
    done
    echo -e "${GREEN}Total skills: $total${NC}"
    echo ""

    echo -e "${CYAN}By category:${NC}"
    for category in "$SKILLS_DIR"/*; do
        if [ -d "$category" ] && [ "$(basename "$category")" != "README.md" ] && [ "$(basename "$category")" != "skill-helper.sh" ]; then
            count=$(find "$category" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
            cat_name=$(basename "$category")
            echo "  • $cat_name: $count skills"
        fi
    done
}

# Function to list categories
list_categories() {
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  📁 Skill Categories${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    for category in "$SKILLS_DIR"/*; do
        if [ -d "$category" ]; then
            cat_name=$(basename "$category")
            if [ "$cat_name" != "README.md" ] && [ "$cat_name" != "skill-helper.sh" ]; then
                count=$(find "$category" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)
                case "$cat_name" in
                    cloud-infrastructure)
                        echo -e "${CYAN}☁️  cloud-infrastructure${NC} ($count skills)"
                        ;;
                    containers-docker)
                        echo -e "${CYAN}🐳 containers-docker${NC} ($count skills)"
                        ;;
                    application-development)
                        echo -e "${CYAN}💻 application-development${NC} ($count skills)"
                        ;;
                    devops-cicd)
                        echo -e "${CYAN}🔧 devops-cicd${NC} ($count skills)"
                        ;;
                    operations-monitoring)
                        echo -e "${CYAN}🔒 operations-monitoring${NC} ($count skills)"
                        ;;
                esac
            fi
        fi
    done
    echo ""
}

# Function to validate a skill has required sections
validate_skill() {
    local skill=$1
    if [ -z "$skill" ]; then
        echo -e "${YELLOW}Usage: $0 validate <skill-name>${NC}"
        return 1
    fi

    local skill_path=$(find_skill "$skill")
    if [ -z "$skill_path" ]; then
        echo -e "${YELLOW}Skill '$skill' not found${NC}"
        return 1
    fi

    local file="$skill_path/GEMINI.md"
    if [ ! -f "$file" ]; then
        file="$skill_path/CLAUDE.md"
        if [ ! -f "$file" ]; then
            echo -e "${YELLOW}No GEMINI.md or CLAUDE.md found for skill '$skill'${NC}"
            return 1
        fi
    fi

    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Validating: $skill ($(basename "$file"))${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""

    local issues=0
    local required_sections=(
        "## Scope"
        "## Core Principles"
        "Communication Style"
        "Expected Output Quality"
        "Skill type:"
    )

    for section in "${required_sections[@]}"; do
        if grep -q "$section" "$file"; then
            echo -e "${GREEN}  ✓ Found: ${section}${NC}"
        else
            echo -e "${YELLOW}  ✗ Missing: ${section}${NC}"
            issues=$((issues + 1))
        fi
    done

    local lines=$(wc -l < "$file")
    echo ""
    echo -e "${CYAN}  Lines: $lines${NC}"

    if [ "$lines" -lt 50 ]; then
        echo -e "${YELLOW}  ⚠ Warning: Skill content is sparse (< 50 lines). Consider expanding.${NC}"
        issues=$((issues + 1))
    fi

    echo ""
    if [ "$issues" -eq 0 ]; then
        echo -e "${GREEN}  ✅ Skill is valid ($lines lines)${NC}"
    else
        echo -e "${YELLOW}  ⚠ $issues issues found${NC}"
    fi
}

# Function to create a new skill with template
new_skill() {
    local skill_path=$1
    if [ -z "$skill_path" ]; then
        echo -e "${YELLOW}Usage: $0 new <category/skill-name>${NC}"
        echo -e "${YELLOW}Example: $0 new cloud-infrastructure/database${NC}"
        return 1
    fi

    local category=$(dirname "$skill_path")
    local skill_name=$(basename "$skill_path")
    local full_path="$SKILLS_DIR/$category/$skill_name"
    local file="$full_path/GEMINI.md"

    if [ -f "$file" ]; then
        echo -e "${YELLOW}Skill '$skill_name' already exists at $full_path${NC}"
        return 1
    fi

    mkdir -p "$full_path"

    cat > "$file" << TEMPLATE
# Skill: $(echo "$skill_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

## Scope

Describe what this skill covers and when it applies.

## Core Principles

- **Principle 1** — Description
- **Principle 2** — Description
- **Principle 3** — Description

## Topic 1

Add specific guidance here.

## Topic 2

Add specific guidance here.

## Topic 3

Add specific guidance here.

## Security Considerations

Describe security-specific guidance for this domain.

## Common Mistakes / Anti-Patterns

- **Anti-pattern 1** — Why it's wrong and what to do instead
- **Anti-pattern 2** — Why it's wrong and what to do instead

## Communication Style

When this skill is active:
- Describe how Gemini should respond
- What format, level of detail, etc.

## Expected Output Quality

- What constitutes a good response with this skill active
- Specific artifacts expected (code snippets, commands, etc.)

---
**Skill type:** Passive
**Applies with:** [related-skill-1, related-skill-2]
**Pairs well with:** personal-engineering-agent
TEMPLATE

    echo -e "${GREEN}Created skill: $skill_name${NC}"
    echo -e "${CYAN}Location: $file${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit $file with actual content"
    echo "  2. Run: $0 validate $skill_name"
}

# Main command dispatcher
case "$1" in
    list|ls)
        list_skills
        ;;
    show|cat)
        show_skill "$2"
        ;;
    search|grep)
        search_skills "$2"
        ;;
    count)
        count_skills
        ;;
    categories|cat)
        list_categories
        ;;
    validate)
        validate_skill "$2"
        ;;
    new)
        new_skill "$2"
        ;;
    help|--help|-h)
        echo "Skills Helper - Manage Gemini CLI Skills"
        echo ""
        echo "Usage:"
        echo "  $0 list|ls               List all skills organized by category"
        echo "  $0 show|cat <skill>      Show content of a specific skill"
        echo "  $0 search|grep <query>   Search for a keyword across all skills"
        echo "  $0 count                 Count total number of skills"
        echo "  $0 categories            List all categories"
        echo "  $0 validate <skill>      Validate a skill has required sections"
        echo "  $0 new <cat/skill>       Create a new skill with template"
        echo "  $0 help                  Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 show aws"
        echo "  $0 search IAM"
        echo "  $0 validate kubernetes"
        echo "  $0 new cloud-infrastructure/database"
        ;;
    *)
        list_skills
        ;;
esac
