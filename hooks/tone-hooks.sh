#!/usr/bin/env bash
#
# tone-hooks.sh — inject house tone + coding standards into Claude Code context,
# and toggle each independently.
#
# Events (wired in settings.json):
#   session-start        → inject tone + coding standards once, up front.
#   user-prompt-submit   → re-inject tone; inject coding standards on coding prompts.
#
# Control:
#   tone-hooks.sh toggle tone on|off        enable/disable the tone
#   tone-hooks.sh toggle standards on|off   enable/disable the coding standards
#   tone-hooks.sh status                    show current state
#
# State lives in flag files under $HARNESS_TONE_STATE (default ~/.claude/tone), so a
# toggle persists across sessions and projects. HARNESS_TONE=off is a master kill switch
# for both; HARNESS_STANDARDS=off disables standards only. Fails silently — never blocks.

cmd="${1:-}"

STATE_DIR="${HARNESS_TONE_STATE:-$HOME/.claude/tone}"
TONE_OFF="$STATE_DIR/.tone-off"
STANDARDS_OFF="$STATE_DIR/.standards-off"

tone_enabled() {
  [ "${HARNESS_TONE:-on}" = "off" ] && return 1
  [ -f "$TONE_OFF" ] && return 1
  return 0
}

standards_enabled() {
  [ "${HARNESS_TONE:-on}" = "off" ] && return 1
  [ "${HARNESS_STANDARDS:-on}" = "off" ] && return 1
  [ -f "$STANDARDS_OFF" ] && return 1
  return 0
}

# Locate source files: project checkout first, then the plugin install, then the global install.
find_tone_dir() {
  local d
  for d in "${CLAUDE_PROJECT_DIR:-}/tone" "${CLAUDE_PLUGIN_ROOT:-}/tone" "$HOME/.claude/tone"; do
    [ -f "$d/tone.md" ] && { printf '%s' "$d"; return 0; }
  done
  return 1
}

# Emit a source file with its anchor comment lines stripped.
emit() { sed '/^<!--/d' "$1" 2>/dev/null || true; }

case "$cmd" in
  session-start|user-prompt-submit)
    tone_dir="$(find_tone_dir)" || exit 0
    [ "$cmd" = "user-prompt-submit" ] && payload="$(cat)"

    tone_enabled && emit "$tone_dir/tone.md"

    if standards_enabled && [ -f "$tone_dir/coding-standards.md" ]; then
      if [ "$cmd" = "session-start" ]; then
        echo; emit "$tone_dir/coding-standards.md"
      # Bias toward inclusion — a false positive just adds context, a miss loses the standards.
      elif printf '%s' "$payload" | grep -Eiq '\b(write|implement|add|create|build|fix|bug|refactor|function|class|method|endpoint|api|component|debug|compile|error|script|code)\b'; then
        echo; emit "$tone_dir/coding-standards.md"
      fi
    fi
    ;;

  toggle)
    mkdir -p "$STATE_DIR" 2>/dev/null
    case "${2:-}:${3:-}" in
      tone:off)      : > "$TONE_OFF";       echo "tone: OFF" ;;
      tone:on)       rm -f "$TONE_OFF";      echo "tone: ON" ;;
      standards:off) : > "$STANDARDS_OFF";  echo "coding standards: OFF" ;;
      standards:on)  rm -f "$STANDARDS_OFF"; echo "coding standards: ON" ;;
      *) echo "usage: tone-hooks.sh toggle {tone|standards} {on|off}" >&2; exit 2 ;;
    esac
    ;;

  status)
    if tone_enabled;      then echo "tone: ON";            else echo "tone: OFF"; fi
    if standards_enabled; then echo "coding standards: ON"; else echo "coding standards: OFF"; fi
    [ "${HARNESS_TONE:-on}" = "off" ] && echo "(HARNESS_TONE=off — master kill switch active)"
    ;;
esac

exit 0
