# AGENTS.md

This file is read by Claude at the start of every session. It describes how to work in this
repo — the skills available, the canonical workflow, and behavioral rules accumulated from
past mistakes. It does not repeat what is in Readme.md or the individual skill files.

---

## This repo is a Claude Code plugin

The repo root is both the `rl-as` plugin and its `agent-harness` marketplace:

- `.claude-plugin/plugin.json` — the `rl-as` plugin manifest.
- `.claude-plugin/marketplace.json` — the `agent-harness` marketplace (one plugin, `source: "."`).
- `skills/<name>/SKILL.md` — auto-discovered skills. When a user installs the plugin they are
  invoked namespaced (`/rl-as:plan`); the `install.sh` fallback installs them un-namespaced (`/plan`).
- `hooks/hooks.json` — auto-loaded; wires `verify-evidence.sh` (PostToolUse) and
  `tone-hooks.sh` (SessionStart + UserPromptSubmit) via `${CLAUDE_PLUGIN_ROOT}`.
- `tone/` — canonical tone + coding-standards source, read by the tone hook at runtime.

Slash commands written below use the bare form for readability; add the `/rl-as:` prefix when
working against a plugin install.

---

## Nested AGENTS.md

Before starting any task, check whether an AGENTS.md exists in the directory you're working
in or any of its parent directories (up to this root). If one exists, read it — it contains
context specific to that part of the codebase. Known nested files:

<!-- nested-agents-index -->
<!-- Add entries here as nested AGENTS.md files are created, e.g.:             -->
<!-- - [skills/plan/AGENTS.md](skills/plan/AGENTS.md) — plan skill conventions -->
<!-- nested-agents-index-end -->

If you create work in a subdirectory that would benefit from persistent local conventions,
create an AGENTS.md there and link it in the index above.

---

## Canonical Workflow

For any non-trivial feature, work proceeds in this order. Do not skip steps — each one is a
skill that can be invoked explicitly.

```
/initialize     →  write or update AGENTS.md in a target project
/problem-spec   →  define the problem, produce docs/<feature>/spec.md
/plan           →  break into steps, produce docs/<feature>/plan.md + docs/<feature>/steps/<step-name>.md
                   (requires spec.md to exist)

  For each step:
    write tests (red) → write code (green) → refactor → commit
    /verify              →  E2E check against live system; produces docs/verify/<branch>-<date>.md
    /clean-code          →  clean up staged code; produces docs/simplify/<branch>-<date>.md
    /review-comprehensive →  comprehensive correctness check; produces docs/reviews/<branch>-<date>.md
    /pr-interactive-walkthrough  →  cognitive understanding check
    human                →  developer signs off
```

Failures in `/verify`, `/clean-code`, or `/review-comprehensive` require fixes or a plan update
before proceeding. The Human column in the plan dashboard cannot be marked ✅ while any prior
column is ❌.

---

## Skills Reference

Each skill has a full SKILL.md. This table is a quick reference only — read the SKILL.md
for complete instructions.

| Skill | Invoke | Purpose |
|---|---|---|
| initialize | `/initialize` | Write or update AGENTS.md in a project with skills reference and workflow |
| problem-spec | `/problem-spec` | Define what is and isn't being solved; produce a spec doc |
| plan | `/plan` | Break a spec into testable TDD chunks with a status dashboard |
| verify | `/verify` | E2E verification — real curl or browser automation against a live system |
| clean-code | `/clean-code` | Apply clear improvements; suggest uncertain ones; never touch tests |
| refactor | `/refactor` | Restructure existing code with Fowler's catalog; Chesterton's Fence on every removal |
| review-comprehensive | `/review-comprehensive` | Comprehensive review — bugs, missed edge cases, unhandled errors; report only |
| pr-interactive-walkthrough | `/pr-interactive-walkthrough` | File-by-file code walkthrough with understanding assessment |
| frontend-design | `/frontend-design` | Build distinctive, production-grade frontend UI |
| systematic-debugging | `/systematic-debugging` | Root-cause-first 4-phase debugging process |
| dispatching-parallel-agents | `/dispatching-parallel-agents` | Split independent tasks across parallel subagents |
| tone | `/tone` | Toggle the house tone and coding standards on/off, independently |

Skills live in `skills/`. Each skill directory contains a `SKILL.md` and optionally
`sub-skills/`, `evals/`, and supporting scripts.

---

## Skill Routing

When the user makes a request, route it through this table before responding. The goal is
to invoke the right skill instead of doing ad-hoc work that bypasses the workflow.

| If the user says... | Invoke |
|---|---|
| "build / add / implement / create [non-trivial feature]" | `/problem-spec` (then `/plan`) |
| "make a plan", "how should we build this", "break this into tasks" | `/plan` (requires spec.md to exist; if not, run `/problem-spec` first) |
| "set up AGENTS.md", "onboard this repo", "install the skills here" | `/initialize` |
| "verify this", "test it end to end", "check that it works", "run the e2e" | `/verify` |
| "simplify this", "clean this up", "is this the simplest version" | `/clean-code` |
| "refactor this", "make this more modular", "this file is too big", "extract X out of Y", "split this up", "reduce coupling" | `/refactor` |
| "review this", "find bugs", "what did I miss", "look for edge cases" | `/review-comprehensive` |
| "walk me through this PR", "explain this code", "do I understand this" | `/pr-interactive-walkthrough` |
| "debug this", "why is X failing", "find the root cause" | `/systematic-debugging` |
| "design this UI", "make this look good", "build the frontend for X" | `/frontend-design` |
| "split this work", "run these in parallel", "dispatch agents" | `/dispatching-parallel-agents` |
| "create a skill", "add a new skill", "improve this skill" | `/skill-creator` |
| "tone off/on", "disable coding standards", "stop being terse", "tone status" | `/tone` |

**Routing rules — read before invoking:**

1. **Bug fixes go to `/systematic-debugging`, not `/problem-spec`.** Specs are for new
   capabilities. If the user says "fix this bug" or "X is broken," skip the spec.
2. **`/plan` requires a spec.** If `docs/<feature>/spec.md` doesn't exist, refuse and run
   `/problem-spec` first. Do not improvise a plan from a verbal description.
3. **`/review-comprehensive` ≠ `/pr-interactive-walkthrough`.** Review hunts for bugs and edge
   cases. Walkthrough tests human comprehension. Both run per step; they are not interchangeable.
4. **`/clean-code` and `/review-comprehensive` have two run modes.** In *workflow mode* (running
   as part of a plan-driven step), the prior-step gate enforces order: Auto Tests → Verify →
   Clean Code → Comp Review. In *standalone mode* (running ad-hoc on staged changes, a PR, or a
   branch diff outside any plan), the gate is skipped — the caller is asking for a one-off pass.
   Don't try to bypass the gate in workflow mode; do feel free to run either skill directly when
   the work isn't tied to a plan.
5. **Don't run a skill as a list.** If you find yourself "summarizing what /clean-code would
   say" or "doing a quick mental review," stop and invoke the actual skill. The sub-skills
   and gates only fire when the skill runs.
6. **Trivial changes don't need the workflow.** A typo fix, a single-line CSS tweak, or a
   one-character rename can be done directly. Use judgment — when in doubt, route through
   the workflow rather than around it.

---

## Behavioral Rules

Rules added here when a pattern of mistakes recurs 3+ times. Starts empty.

<!-- learned-rules -->
<!-- learned-rules-end -->

---

## Conversation Tone

House voice for all prose. Source of truth: `tone/tone.md` (the SessionStart /
UserPromptSubmit hooks inject it every turn). Disable with `HARNESS_TONE=off`.

<!-- tone -->

Precise and concise.

- Lead with the answer. No preamble, no restating the user's request back to them.
- Drop articles (a/an/the) where meaning stays clear.
- Drop filler (just/really/basically/actually/simply), hedging (maybe/perhaps/I think),
  and pleasantries (sure/certainly/of course/happy to/great question).
- Be logically precise; use exact words for concepts. If unsure, raise it.
- Pass errors, stack traces, code, commands, and exact file paths through verbatim —
  never paraphrase, truncate, or "clean up" an error string.
- Fragments are fine. Short synonyms over long ones (big, not extensive).

For user questions:

- Always ask one question at a time. Handle all follow-ups before moving on to the next question.

Scope: applies to prose only. Never alter code blocks, commit messages, security warnings, error messages, or PR bodies —
those stay in normal, complete form.

<!-- tone-end -->

---

## Coding Standards

Applied before writing code. Source of truth: `tone/coding-standards.md` (the
UserPromptSubmit hook injects it when the prompt reads as a coding request).

<!-- coding-standards -->

Apply before writing code, not after. Stop at the first rung that resolves the task.

1. Think first. State assumptions explicitly. If the request is ambiguous, ask before
   coding — do not guess and proceed. Surface tradeoffs and simpler alternatives up front.

2. Necessity (YAGNI). Does this need to be built at all? Do not add speculative features,
   flexibility, or error handling for scenarios no one asked for.

3. Reuse before writing. In order: existing helpers/patterns in this codebase → standard
   library → native platform feature → an already-installed dependency → one line → only
   then write new code. Do not add a dependency you can avoid.

4. Simplicity. Write the minimum code that solves the problem. No premature abstractions,
   base classes, or design patterns until an actual requirement demands them.

5. Surgical changes. Touch only what the task requires. Match the surrounding style even
   if you'd do it differently. Fix the bug first; refactor separately. Remove only code
   your change made obsolete — leave unrelated dead code alone.

6. Verify. For non-trivial logic, write the failing test first, then make it pass. Break
   multi-step work into independently checkable stages with explicit success criteria.
   Trivial one-liners skip tests.

7. Safety invariants — never optimize these away, even under "make it minimal": input
   validation at trust boundaries, error handling that prevents data loss, security
   (auth/crypto/secrets), and accessibility.

These front-load the same values the /clean-code, /refactor, and /review-comprehensive
skills enforce later — the goal is a first draft that's already close.

<!-- coding-standards-end -->

---

## What This File Is Not

- Not a duplicate of Readme.md (see that for repo purpose)
- Not a directory listing (derive structure from the repo itself)
- Not a copy of individual SKILL.md files (read those directly)
