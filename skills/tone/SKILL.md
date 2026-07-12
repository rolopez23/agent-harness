---
name: tone
description: >
  Toggles the house conversation tone and coding standards on or off, independently.
  These are injected each turn by the tone-hooks.sh SessionStart/UserPromptSubmit hooks;
  this skill flips the persistent flag files that gate them. Trigger when the user says
  "turn off the tone", "disable coding standards", "tone off", "standards on", "stop being
  terse", "tone status", or "what's my tone setting". Scope of the change persists across
  sessions and projects until toggled back.
---

# Tone

Enable or disable the house **tone** and **coding standards** independently. State is held
in flag files (`~/.claude/tone/.tone-off`, `~/.claude/tone/.standards-off`) read by the
hooks every turn, so a change sticks until reversed.

## Step 1: Locate the toggle script

Use the first that exists:

1. `$HOME/.claude/hooks/tone-hooks.sh` (global install)
2. `$CLAUDE_PROJECT_DIR/hooks/tone-hooks.sh` or `./hooks/tone-hooks.sh` (harness checkout)

## Step 2: Map the request to a command

| User says | Run |
|---|---|
| "tone off", "disable tone", "stop being terse" | `tone-hooks.sh toggle tone off` |
| "tone on", "enable tone" | `tone-hooks.sh toggle tone on` |
| "standards off", "disable coding standards" | `tone-hooks.sh toggle standards off` |
| "standards on", "enable coding standards" | `tone-hooks.sh toggle standards on` |
| "everything off", "turn it all off" | both `toggle tone off` and `toggle standards off` |
| "everything on", "turn it all back on" | both `toggle tone on` and `toggle standards on` |
| "tone status", "what's my setting" | `tone-hooks.sh status` |

If the request is ambiguous about which of the two (tone vs standards), ask before running.

## Step 3: Run it and confirm

Run the command(s), then run `tone-hooks.sh status` and report the resulting state back to
the user in one line. The change takes effect on the next turn (the hook reads the flags
fresh each prompt).

Note: `HARNESS_TONE=off` in the environment is a master kill switch that overrides these
flags. If status shows that line, tell the user to unset it to re-enable.
