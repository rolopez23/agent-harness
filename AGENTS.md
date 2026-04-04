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
| review | `/review` | Find bugs, missed edge cases, unhandled errors; report only |
| learn-from-mistakes | `/learn-from-mistakes` | Log corrections and gaps after human sign-off |
| frontend-design | `/frontend-design` | Build distinctive, production-grade frontend UI |
| systematic-debugging | `/systematic-debugging` | Root-cause-first 4-phase debugging process |
| dispatching-parallel-agents | `/dispatching-parallel-agents` | Split independent tasks across parallel subagents |

Skills live in `skills/`. Each skill directory contains a `SKILL.md` and optionally
`sub-skills/`, `evals/`, and supporting scripts.

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
