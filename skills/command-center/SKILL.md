---
name: command-center
description: >
  Show all Claude Code sessions as a table — title, active/idle, branch, and worktree.
  Trigger when the user asks to list, show, or review their Claude sessions, see which
  sessions are active/running, or "open the command center". Also trigger on
  "show my sessions", "which sessions are live", "session dashboard".
disable-model-invocation: true
version: "1.0.0"
---

# Command Center

List every Claude Code session on this machine with a one-line title, whether it is
active, and the git branch / worktree it last ran on.

## Run it

The script lives next to this SKILL.md. It reads absolute paths under
`~/.claude/projects`, so run it from anywhere — pass the script's own directory:

```bash
python3 "<this-skill-dir>/command_center.py" all      # every project (default)
python3 "<this-skill-dir>/command_center.py" current  # only the current project
```

The script prints a ready-to-display markdown table. Show its output verbatim — do
not re-derive the data by hand.

## What each column means

- **Modified** — transcript file mtime (`MM-DD HH:MM`).
- **ID** — first 8 chars of the session UUID (the `.jsonl` basename under
  `~/.claude/projects/<slug>/`).
- **Active** — `✅ live` / `⛔ idle`. See heuristic below.
- **Branch** — distinct `gitBranch` values the session logged, in order (`a → b`).
- **Worktree** — the `.claude/worktrees/<name>` dir if the session ran in one, else `—`.
- **Title** — an explicit `/slash` command if the session opened with one, else the
  first real user prompt (the local-command caveat boilerplate is stripped).

## How "Active" is decided (and its limits)

There is **no reliable fd-based signal**: Claude Code appends to the transcript then
closes it, and exposes no session id in the process env or argv. So the script:

1. Lists live `claude` processes (`ps`) and each one's cwd (`lsof -d cwd`).
2. Counts live processes per project.
3. Marks the **N most-recently-modified** sessions in that project `✅ live`.

The currently-running session is always the most-recent transcript in its project, so
it is always flagged. The tradeoff: with multiple sessions in one project, a paused
session can be mis-flagged and a very recently-closed one can still show live. Branch
and worktree are **last-logged** values, not live git state.

## Notes

- Read-only: touches only `~/.claude/projects/**` and `ps`/`lsof`. Writes nothing.
- Requires `python3` (stdlib only) and, for accurate active detection, `lsof`.
