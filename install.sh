#!/usr/bin/env bash
# install.sh — install harness skills into any repo
# Usage: ./install.sh [target-dir]
#   target-dir defaults to current working directory

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(cd "${1:-.}" && pwd)"
SKILLS_SRC="$HARNESS_DIR/skills"
SKILLS_DST="$TARGET_DIR/.claude/skills"

# ── helpers ───────────────────────────────────────────────────────────────────

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

# ── 1. copy skills ────────────────────────────────────────────────────────────

mkdir -p "$SKILLS_DST"

installed=()
updated=()

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_dir")"
  dst="$SKILLS_DST/$skill_name"

  if [[ -d "$dst" ]]; then
    rm -rf "$dst"
    cp -r "$skill_dir" "$dst"
    updated+=("$skill_name")
  else
    cp -r "$skill_dir" "$dst"
    installed+=("$skill_name")
  fi
done

bold "Skills → $SKILLS_DST"
for s in "${installed[@]+"${installed[@]}"}"; do green  "  + $s"; done
for s in "${updated[@]+"${updated[@]}"}";    do yellow "  ↺ $s"; done

# ── 2. context files (AGENTS.md + CLAUDE.md) ─────────────────────────────────

HARNESS_REL="$(python3 -c "import os; print(os.path.relpath('$HARNESS_DIR', '$TARGET_DIR'))" 2>/dev/null || echo "$HARNESS_DIR")"

skills_table() {
  cat <<EOF
| Skill | Invoke | SKILL.md |
|---|---|---|
| initialize | \`/initialize\` | [→]($HARNESS_REL/skills/initialize/SKILL.md) |
| problem-spec | \`/problem-spec\` | [→]($HARNESS_REL/skills/problem-spec/SKILL.md) |
| plan | \`/plan\` | [→]($HARNESS_REL/skills/plan/SKILL.md) |
| verify | \`/verify\` | [→]($HARNESS_REL/skills/verify/SKILL.md) |
| simplify | \`/simplify\` | [→]($HARNESS_REL/skills/simplify/SKILL.md) |
| review | \`/review\` | [→]($HARNESS_REL/skills/review/SKILL.md) |
| learn-from-mistakes | \`/learn-from-mistakes\` | [→]($HARNESS_REL/skills/learn-from-mistakes/SKILL.md) |
EOF
}

workflow_block() {
  printf '```\n'
  cat <<'EOF'
/initialize     →  write or update context files in a target project
/problem-spec   →  define the problem, produce docs/<feature>/spec.md
/plan           →  break into TDD chunks, produce docs/<feature>/plan.md

  For each step:
    write tests (red) → write code (green) → refactor → commit
    /verify    →  E2E check against live system
    /simplify  →  clean up staged code
    /review    →  correctness and edge case check
    /pr-interactive-walkthrough  →  cognitive understanding check
    human      →  sign off

/learn-from-mistakes  →  log corrections; updates .claude/learnings.md
EOF
  printf '```\n'
}

# write_context_file <path> <title>
write_context_file() {
  local file="$1"
  local title="$2"   # e.g. "AGENTS.md" or "CLAUDE.md"
  local nested_label="$title"

  cat > "$file" <<EOF
# $title

Read by Claude at the start of every session. Links to skill files rather than
duplicating them. For full instructions, read the linked SKILL.md.

---

## Nested $nested_label

Check for $nested_label in subdirectories before starting work in them.

<!-- nested-agents-index -->
<!-- nested-agents-index-end -->

---

## Workflow

For non-trivial features, follow this order:

$(workflow_block)

---

## Skills

$(skills_table)

---

## Behavioral Rules

Rules added by \`/learn-from-mistakes\` when a pattern recurs 3+ times.

<!-- learned-rules -->
<!-- learned-rules-end -->
EOF
}

# update_context_file <path> <label>
update_context_file() {
  local file="$1"
  local label="$2"
  local changed=false

  if ! grep -q '## Skills' "$file"; then
    printf '\n---\n\n## Skills\n\n%s\n' "$(skills_table)" >> "$file"
    green "  + added ## Skills"
    changed=true
  fi

  if ! grep -q '## Workflow' "$file"; then
    printf '\n---\n\n## Workflow\n\nFor non-trivial features, follow this order:\n\n%s\n' "$(workflow_block)" >> "$file"
    green "  + added ## Workflow"
    changed=true
  fi

  if ! grep -q 'nested-agents-index' "$file"; then
    printf '\n---\n\n## Nested %s\n\nCheck for %s in subdirectories before starting work in them.\n\n<!-- nested-agents-index -->\n<!-- nested-agents-index-end -->\n' "$label" "$label" >> "$file"
    green "  + added nested index"
    changed=true
  fi

  if ! grep -q 'learned-rules' "$file"; then
    printf '\n---\n\n## Behavioral Rules\n\nRules added by `/learn-from-mistakes` when a pattern recurs 3+ times.\n\n<!-- learned-rules -->\n<!-- learned-rules-end -->\n' >> "$file"
    green "  + added learned-rules block"
    changed=true
  fi

  if $changed; then
    green "Updated $file"
  else
    yellow "$file already complete — no changes"
  fi
}

# ── process each context file ─────────────────────────────────────────────────

printf '\n'
bold "Context files → $TARGET_DIR"

for fname in AGENTS.md CLAUDE.md; do
  target_file="$TARGET_DIR/$fname"
  if [[ ! -f "$target_file" ]]; then
    write_context_file "$target_file" "$fname"
    green "Created $target_file"
  else
    update_context_file "$target_file" "$fname"
  fi
done

# ── done ──────────────────────────────────────────────────────────────────────

printf '\n'
bold "Done. Next steps:"
echo "  cd $TARGET_DIR"
echo "  claude          # start a session — skills are active"
echo "  /problem-spec   # begin your first feature"
