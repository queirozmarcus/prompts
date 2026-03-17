#!/bin/bash
echo "═══════════════════════════════════════"
echo "  Agent Ecosystem Validator v5.0.0"
echo "═══════════════════════════════════════"
echo ""
ERRORS=0

# 1. Marcus
echo "▸ Marcus (global orchestrator)..."
if [ -f "marcus-agent.md" ] && head -1 "marcus-agent.md" | grep -q '^---$'; then
  echo "  ✓ marcus-agent.md"
else
  echo "  ✗ marcus-agent.md MISSING or no frontmatter"
  ERRORS=$((ERRORS+1))
fi
echo ""

# 2. No standalone agents (should only have marcus, CLAUDE.md, README.md, validate)
echo "▸ No standalone agents (all must be in packs)..."
orphans=$(find . -maxdepth 1 -name "*-agent.md" ! -name "marcus-agent.md" 2>/dev/null)
if [ -z "$orphans" ]; then
  echo "  ✓ Clean — only Marcus at root"
else
  echo "  ✗ ORPHAN STANDALONE AGENTS:"
  echo "$orphans" | sed 's/^/    /'
  ERRORS=$((ERRORS+1))
fi
echo ""

# 3. Pack agents frontmatter
echo "▸ Pack agents..."
for f in teams-agents-*/.claude/agents/*.md; do
  ok="✓"
  head -1 "$f" | grep -q '^---$' || { ok="✗"; ERRORS=$((ERRORS+1)); }
  echo "  $ok $(basename "$f")"
done
echo ""

# 4. Name collisions
echo "▸ Name collisions..."
dupes=$(for d in teams-agents-*/.claude/agents/; do ls "$d" 2>/dev/null; done | sort | uniq -d)
[ -z "$dupes" ] && echo "  ✓ None" || { echo "  ✗ $dupes"; ERRORS=$((ERRORS+1)); }
echo ""

# 5. Junk
echo "▸ Junk files..."
junk=$(find . -name "*Zone.Identifier*" -o -type d -name "*{*" 2>/dev/null | head -3)
[ -z "$junk" ] && echo "  ✓ Clean" || { echo "  ✗ $junk"; ERRORS=$((ERRORS+1)); }
echo ""

# 6. Inventory
echo "▸ Inventory:"
echo "  Marcus: 1 (global)"
for d in teams-agents-*/; do
  a=$(find "$d.claude/agents" -name '*.md' 2>/dev/null | wc -l)
  c=$(find "$d.claude/commands" -name '*.md' 2>/dev/null | wc -l)
  echo "  $d ${a} agents, ${c} commands"
done
pack_agents=$(find teams-agents-*/.claude/agents/ -name '*.md' | wc -l)
pack_cmds=$(find teams-agents-*/.claude/commands/ -name '*.md' | wc -l)
forks=$(grep -rl "context: fork" teams-agents-*/.claude/agents/ 2>/dev/null | wc -l)
echo "  ─────────────"
echo "  TOTAL: $((pack_agents + 1)) agents (1 Marcus + $pack_agents pack), $pack_cmds commands, $forks with context:fork"
echo ""

echo "═══════════════════════════════════════"
[ $ERRORS -eq 0 ] && echo "  ✅ ALL CHECKS PASSED" || echo "  ✗ FAILED: $ERRORS error(s)"
echo "═══════════════════════════════════════"
exit $ERRORS
