# AGENTS.md

This file is read by Claude at the start of every session. It describes how to work in this
repo — the skills available, the canonical workflow, and behavioral rules accumulated from
past mistakes. It does not repeat what is in Readme.md or the individual skill files.

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
    /verify     →  E2E check against live system; produces docs/verify/<branch>-<date>.md
    /simplify   →  clean up staged code; produces docs/simplify/<branch>-<date>.md
    /review     →  correctness check; produces docs/reviews/<branch>-<date>.md
    /pr-interactive-walkthrough  →  cognitive understanding check
    human       →  developer signs off

/learn-from-mistakes  →  log corrections and gaps; updates .claude/learnings.md
```

Failures in `/verify`, `/simplify`, or `/review` require fixes or a plan update before
proceeding. The Human column in the plan dashboard cannot be marked ✅ while any prior
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
| simplify | `/simplify` | Apply clear improvements; suggest uncertain ones; never touch tests |
| refactor | `/refactor` | Restructure existing code with Fowler's catalog; Chesterton's Fence on every removal |
| review | `/review` | Find bugs, missed edge cases, unhandled errors; report only |
| pr-interactive-walkthrough | `/pr-interactive-walkthrough` | File-by-file code walkthrough with understanding assessment |
| learn-from-mistakes | `/learn-from-mistakes` | Log corrections and gaps after human sign-off |
| frontend-design | `/frontend-design` | Build distinctive, production-grade frontend UI |
| systematic-debugging | `/systematic-debugging` | Root-cause-first 4-phase debugging process |
| dispatching-parallel-agents | `/dispatching-parallel-agents` | Split independent tasks across parallel subagents |

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
| "simplify this", "clean this up", "is this the simplest version" | `/simplify` |
| "refactor this", "make this more modular", "this file is too big", "extract X out of Y", "split this up", "reduce coupling" | `/refactor` |
| "review this", "find bugs", "what did I miss", "look for edge cases" | `/review` |
| "walk me through this PR", "explain this code", "do I understand this" | `/pr-interactive-walkthrough` |
| "what went wrong", "log the corrections", "retrospective", "learn from this" | `/learn-from-mistakes` |
| "debug this", "why is X failing", "find the root cause" | `/systematic-debugging` |
| "design this UI", "make this look good", "build the frontend for X" | `/frontend-design` |
| "split this work", "run these in parallel", "dispatch agents" | `/dispatching-parallel-agents` |
| "create a skill", "add a new skill", "improve this skill" | `/skill-creator` |

**Routing rules — read before invoking:**

1. **Bug fixes go to `/systematic-debugging`, not `/problem-spec`.** Specs are for new
   capabilities. If the user says "fix this bug" or "X is broken," skip the spec.
2. **`/plan` requires a spec.** If `docs/<feature>/spec.md` doesn't exist, refuse and run
   `/problem-spec` first. Do not improvise a plan from a verbal description.
3. **`/review` ≠ `/pr-interactive-walkthrough`.** Review hunts for bugs and edge cases.
   Walkthrough tests human comprehension. Both run per step; they are not interchangeable.
4. **`/simplify` and `/review` have two run modes.** In *workflow mode* (running as part of
   a plan-driven step), the prior-step gate enforces order: Auto Tests → Verify → Simplify
   → Review. In *standalone mode* (running ad-hoc on staged changes, a PR, or a branch diff
   outside any plan), the gate is skipped — the caller is asking for a one-off pass. Don't
   try to bypass the gate in workflow mode; do feel free to run either skill directly when
   the work isn't tied to a plan.
5. **Don't run a skill as a list.** If you find yourself "summarizing what /simplify would
   say" or "doing a quick mental review," stop and invoke the actual skill. The sub-skills
   and gates only fire when the skill runs.
6. **Trivial changes don't need the workflow.** A typo fix, a single-line CSS tweak, or a
   one-character rename can be done directly. Use judgment — when in doubt, route through
   the workflow rather than around it.

---

## Behavioral Rules

Rules added here by `/learn-from-mistakes` when a pattern occurs 3+ times. Starts empty.

<!-- learned-rules -->
<!-- learned-rules-end -->

---

## What This File Is Not

- Not a duplicate of Readme.md (see that for repo purpose)
- Not a directory listing (derive structure from the repo itself)
- Not a copy of individual SKILL.md files (read those directly)
