---
name: learn-from-mistakes
description: >
  Runs after human sign-off on a chunk. Logs human corrections, missed cases, and
  implementation holes for pattern tracking. Does not fix anything — the goal is to accumulate
  insight over time. When the same class of mistake occurs 3 or more times, surfaces a concrete
  suggestion to update AGENTS.md or an existing skill.
  Trigger after a human marks a chunk complete, when the user says "log what went wrong",
  "retrospective", "what did we miss", or "learn from this".
---

# Learn From Mistakes

You are running a lightweight retrospective on a completed chunk. You are not fixing anything.
You are logging what happened so that patterns can emerge over time and improve future work.

## What to Collect

Read the output files for this chunk in order:

1. `docs/verify/<branch>-*.md` — what failed or was incomplete during E2E verification
2. `docs/simplify/<branch>-*.md` — what was simplified, what was suggested
3. `docs/reviews/<branch>-*.md` — bugs, edge cases, contract violations found
4. The chunk sub-plan (`docs/<feature>/chunks/<NN>-<chunk-name>.md`) — compare what was
   planned vs. what actually happened
5. Any human corrections — ask the user: "Were there any corrections you made after the
   automated steps? Anything that only became obvious during human review?"

## What Counts as a Loggable Event

Log an event when something required unexpected correction or was missed by an earlier step.
Categories:

- **Human correction** — the human changed or rejected something after automated steps passed
- **Missed edge case** — a case not caught by tests, verify, or review that surfaced later
- **Implementation hole** — something in the spec that wasn't implemented, discovered late
- **Bad assumption** — code was written based on an assumption that turned out to be wrong
- **Large refactor** — a significant simplification or improvement that was only caught in the simplify step.
- **Skill gap** — a class of problem the review/simplify/verify skills consistently miss
- **Test gap** — automated tests passed but the behavior was still wrong (test didn't cover it)

Do not log:

- Minor things caught in the workflow. Large refactors or token use in between steps are worth noting, but small things that are caught in the normal course of work aren't worth logging.
- Style preferences or subjective disagreements
- One-off environmental issues (server wasn't running, wrong config)

## The Learning Log

Append entries to `.claude/learnings.md`. Create the file if it doesn't exist.

Each entry follows this format:

```markdown
### <YYYY-MM-DD> · <feature>/<chunk>

**Category**: <Human correction | Missed edge case | Implementation hole | Bad assumption | Skill gap | Test gap>
**What happened**: <1–2 sentences describing the specific mistake or gap>
**Where it surfaced**: <which step caught it, or "human review">
**Pattern tag**: `<short-kebab-case-tag>` (e.g. `nil-not-checked`, `auth-missing`, `off-by-one`, `concurrent-write`)
```

The pattern tag is the key field — it's how recurring issues are detected.

## Detecting Patterns

After appending the new entries, scan `.claude/learnings.md` for pattern tags that appear
3 or more times. For each such tag:

1. List the occurrences (dates, features, brief descriptions)
2. Determine whether the fix belongs in:
   - **AGENTS.md** — if it's a behavioral reminder Claude should always follow (e.g. "always
     check for nil before calling methods on optional associations")
   - **A skill update** — if a specific skill (review, simplify, verify, plan, tdd-chunk)
     consistently misses this class of problem
3. Draft the suggestion (see format below) but do not apply it — present it to the user

## Suggesting a Fix

When a pattern crosses the 3-occurrence threshold, output:

```
## Pattern Detected: `<tag>`

Occurred <N> times:
- <date> · <feature/chunk> — <one-line summary>
- ...

**Suggested fix:**
→ **AGENTS.md addition**: "<the rule to add, written as a direct instruction>"
— or —
→ **Skill update** (<skill name>): "<what to add or change in the skill, and where>"

Apply this? (yes / no / later)
```

Wait for the user's response before making any changes to AGENTS.md or skill files.

## Save the Output

Append to `.claude/learnings.md` (the cumulative log). Also save a per-session summary to
`docs/learnings/<feature>-<chunk>-<YYYY-MM-DD>.md` for traceability.

Tell the user:

- How many events were logged
- Whether any patterns crossed the threshold
- Where the files were saved

## Update the Plan

Mark the Human column ✅ in plan.md if it isn't already — this skill runs after human
sign-off, so by the time it runs that column should be getting its final update.
