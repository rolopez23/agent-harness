---
name: initialize
description: >
  Installs this harness's skills into a project by writing or updating AGENTS.md and/or
  CLAUDE.md with a skills reference and canonical workflow, plus a gitignored ai-sessions/
  folder and .claude/settings.json read-permission defaults. Run this when setting up a new
  project, onboarding a repo to the spec→plan→TDD→verify→clean-code→review workflow, or
  when a project's context files are missing or don't reference these skills. Trigger when the
  user says "initialize this project", "set up AGENTS.md", "set up CLAUDE.md", "install
  skills", "onboard this repo", or "add skills to this project".
disable-model-invocation: true
version: "1.1.0"
---

# Initialize

Install this harness's skills into a target project by writing or updating its context files.

Claude Code reads **CLAUDE.md** for project context. Codex and other agents read **AGENTS.md**.
Both serve the same purpose — orient the AI in a new session. This skill writes whichever
file(s) the project needs.

The goal is minimal files that link out to canonical skill files rather than duplicating their
contents. Less is more.

## Step 1: Locate the tone source files

The workflow, skills, and behavioral-rules blocks below are self-contained templates — you
don't need the harness on disk to write them. You only need the harness's `tone/` directory
to embed the tone + coding-standards sections verbatim (Step: Conversation Tone).

Find the first `tone/` that exists, in order:

1. `${CLAUDE_PLUGIN_ROOT}/tone` — when the harness is installed as the `rl-as` plugin
2. `$HOME/.claude/tone` — when installed via the `install.sh` fallback
3. `./tone` — when running inside the harness checkout itself

If none exists, write the other sections and tell the user the tone sections were skipped
(harness source not found).

## Step 2: Identify the target project

Usually the current working directory. If the user provided a path, use that.

If ambiguous, ask: "Which directory should I initialize — this one (`<cwd>`), or somewhere
else?"

## Step 3: Determine which files to write

Check what exists at the target project root:

| State | Action |
|---|---|
| Neither file exists | Create both CLAUDE.md and AGENTS.md |
| Only CLAUDE.md exists | Update CLAUDE.md; create AGENTS.md |
| Only AGENTS.md exists | Update AGENTS.md; create CLAUDE.md |
| Both exist | Update both |

If the user explicitly said "only CLAUDE.md" or "only AGENTS.md", respect that and skip the
other.

---

## Content blocks

Both files use the same sections. Tailor the heading style to the file (CLAUDE.md can
use a friendlier intro; AGENTS.md is terse).

### Nested context index

```markdown
## Nested AGENTS.md / CLAUDE.md

Check for context files in subdirectories before starting work in them.

<!-- nested-agents-index -->
<!-- nested-agents-index-end -->
```

### AI sessions

```markdown
## AI sessions

`ai-sessions/` is gitignored and holds every artifact an AI session produces.

- `ai-sessions/<YYYY-MM-DD>-<feature>/` is one folder per feature or workstream for specs,
  plans, notes, verify/review reports and a `summary.md`. Ad-hoc work gets its own dated folder.
- `ai-sessions/sessions.md` indexes those folders (**In progress** / **Completed**) with
  their `claude --resume <session-id>` commands.

Rules for agents:

1. At session start, reuse the feature's existing folder (`ls -d ai-sessions/*-<feature>/`)
   and add this session's resume command to its row; otherwise create the folder and add a
   row under **In progress**. Get the session ID from the scratchpad path or `/status`.
2. Write session artifacts to that folder, not to scratchpad or `/tmp`.
3. At session end, update `summary.md` (goal, done, time sinks, open items). When the
   feature is done, move its row to **Completed**.
4. Exception: files the code or other contributors depend on stay committed in `docs/`.
```

### Workflow

Commands below use the `/rl-as:` plugin prefix. If the harness was installed via the
`install.sh` fallback instead, drop the prefix (`/plan`, `/verify`, …).

```
/rl-as:initialize     →  write or update context files in a target project
/rl-as:problem-spec   →  define the problem, produce ai-sessions/<YYYY-MM-DD>-<feature>/spec.md
/rl-as:plan           →  break into TDD chunks, produce ai-sessions/<YYYY-MM-DD>-<feature>/plan.md

  For each step:
    write tests (red) → write code (green) → refactor → commit
    /rl-as:verify               →  E2E check against live system
    /rl-as:clean-code           →  clean up staged code
    /rl-as:review-comprehensive →  comprehensive correctness and edge case check
    /rl-as:pr-interactive-walkthrough  →  cognitive understanding check
    human                       →  sign off
```

### Skills table

Skills ship with the `rl-as` plugin (or the `install.sh` fallback), so there's no on-disk
path to link — reference them by their invocation command. The plugin namespaces them as
`/rl-as:<skill>`; the fallback install uses the bare `/<skill>` form.

```markdown
## Skills

| Skill | Invoke |
|---|---|
| initialize | `/rl-as:initialize` |
| problem-spec | `/rl-as:problem-spec` |
| plan | `/rl-as:plan` |
| verify | `/rl-as:verify` |
| clean-code | `/rl-as:clean-code` |
| review-comprehensive | `/rl-as:review-comprehensive` |
```

### Behavioral rules block

```markdown
## Behavioral Rules

Rules added when a pattern of mistakes recurs 3+ times.

<!-- learned-rules -->
<!-- learned-rules-end -->
```

### Conversation Tone and Coding Standards

Copy these two sections in verbatim from the harness's canonical source files — do not
rewrite them. Read `tone.md` and `coding-standards.md` from the `tone/` directory located in
Step 1 and paste each file's content (including its `<!-- tone -->` / `<!-- coding-standards -->`
anchors) under the matching heading:

```markdown
## Conversation Tone

<!-- contents of tone/tone.md -->

## Coding Standards

<!-- contents of tone/coding-standards.md -->
```

These are injected at runtime by `tone-hooks.sh`; including them here keeps them visible in
the project's context file and lets a human edit the wording per project.

---

## Creating a file

Write only what's needed. Minimal example:

```markdown
# CLAUDE.md

Read by Claude at the start of every session. Links to skill files — read those for full
instructions.

---

## Nested CLAUDE.md
...

---

## AI sessions
...

---

## Workflow
...

---

## Skills
...

---

## Behavioral Rules
...
```

Use `# AGENTS.md` / `# CLAUDE.md` as the title to match the file. The body is identical
either way.

---

## Updating a file

Read the existing file. Add only what's missing — do not remove, reorder, or rewrite
anything that already exists.

Check for each section by marker:

| Section | Marker to look for |
|---|---|
| Nested index | `nested-agents-index` |
| AI sessions | `## AI sessions` |
| Workflow | `## Workflow` |
| Skills table | `## Skills` |
| Behavioral rules | `learned-rules` |
| Conversation tone | `<!-- tone -->` |
| Coding standards | `<!-- coding-standards -->` |

For the Skills table specifically: if the section exists, check each skill row individually
and append any missing rows. Do not duplicate rows that are already present.

Append missing sections at the end of the file, separated by `---`.

---

## Project files

Also set these up at the target project root, adding only what's missing.

**`.gitignore`** (create if missing) — skip if an `ai-sessions/` or `/ai-sessions/` line
exists:

```gitignore
# AI session artifacts; see "AI sessions" in AGENTS.md / CLAUDE.md
ai-sessions/
```

**`ai-sessions/sessions.md`** — create only if missing:

```markdown
# AI sessions

One row per feature folder. Run resume commands from the repo root.

## In progress

| Folder | Name / purpose | Started | Resume |
|---|---|---|---|

## Completed

| Folder | Name / purpose | Started | Finished | Outcome | Resume |
|---|---|---|---|---|---|
```

**`.claude/settings.json`**:

```json
{
  "permissions": {
    "ask": [
      "Read(**/node_modules/**)",
      "Read(**/.venv/**)",
      "Read(**/.next/**)",
      "Read(**/__pycache__/**)"
    ],
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.local)",
      "Read(**/.env.*.local)",
      "Read(**/.env.production)"
    ]
  }
}
```

If the file exists, merge: append each missing entry to `permissions.ask` / `permissions.deny`
(create the arrays if absent). Never replace existing arrays, drop keys, or duplicate
entries. If the file isn't valid JSON, don't touch it — tell the user.

---

## After Writing

Tell the user:

- Which files were created vs. updated (context files, `.gitignore`, `sessions.md`,
  `settings.json`)
- Which sections were added to each
- The paths written
- One-liner next step: "Run `/problem-spec` to start your first feature, or `/plan` if you
  already have a spec."
