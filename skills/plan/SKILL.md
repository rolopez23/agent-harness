---
name: plan
description: >
  Creates a structured implementation plan from a problem spec, breaking work into independently
  testable chunks with dependency tracking and a living status dashboard.
  ONLY trigger this skill when a problem spec already exists at docs/<feature>/spec.md — if no spec
  is present, simpler ad-hoc planning suffices and this skill should not be used.
  Trigger on: "make a plan", "plan this out", "how should we implement this", "create an
  implementation plan", "break this into tasks", "what order should we build this in" — but only
  when a spec.md exists. If the user asks to plan something and there is no spec, tell them to run
  /problem-spec first.
---

# Plan Skill

You are creating a living implementation plan from a problem spec. The goal is to break the work
into chunks that can be built, tested, and verified independently — and to track the state of each
chunk as the work proceeds.

## Before You Start

Locate the spec. It should be at `docs/<feature-name>/spec.md`. Read it fully. If it does not
exist, stop and tell the user: "I need a problem spec before I can make a plan. Run /problem-spec
first."

## What Makes a Good Chunk

A chunk is a unit of work that can be tested on its own. Good chunks:

- Have a clear, observable outcome (something you can assert about)
- Map to a coherent layer or behavior (data model, API endpoint, background job, UI component)
- Are small enough that one person can hold the whole thing in their head
- Are large enough that testing them tells you something meaningful

Poor chunks are either too fine-grained (single function) or too coarse (the whole feature at once).
When in doubt, split at natural seams: schema changes, new API surfaces, new integrations.

Each chunk should have, at minimum, automated tests. Where the behavior surfaces externally (an
API endpoint, a background job, a UI flow), there should also be an LLM verification step — the
LLM runs the code (curl, script, test suite, whatever is natural) and confirms the behavior is
correct. This doesn't need to be a scripted/automated test; it's a verification pass where the
LLM actively exercises the code and checks the result.

## Step 1: Decompose the Spec into Chunks

Read through the "What We Are Solving" and "Interfaces" sections of the spec. Identify the natural
layers of implementation. Typical patterns:

- Data layer (migrations, models, schema changes)
- Core logic (service objects, domain rules, background jobs)
- API / transport layer (controllers, routes, serializers)
- Integration points (mailers, external services, webhooks)
- Frontend / UI (if applicable)

Name each chunk concisely (e.g. "notifications schema", "comment event triggers", "feed API",
"email delivery"). Number them in a suggested build order.

## Step 2: Map Dependencies

For each chunk, identify which other chunks it blocks or is blocked by. Be explicit: "chunk 3
cannot be meaningfully tested until chunk 1 is complete" is a blocking dependency. "chunk 4 can
be built in parallel with chunk 3" is worth calling out.

Express dependencies as: chunk N blocks chunks [X, Y]. An empty blocks list means the chunk is
a leaf — it can be shipped and verified without anything downstream waiting on it.

## Step 3: Choose a Branching Strategy

Based on the chunk count, dependency structure, and team size, recommend a branching approach:

- **Single feature branch**: best for tightly coupled, sequential chunks where parallelism isn't
  practical. One branch, commits per chunk.
- **Per-chunk branches**: best for chunks with few dependencies that can be reviewed and merged
  independently.
- **Worktrees**: best for chunks that are truly independent and you want to work on simultaneously
  without context-switching.

State your recommendation and reasoning briefly. The user may override it — whatever they choose,
record it in the plan.

## Step 4: Write the Plan Document

Write the main plan to `docs/<feature-name>/plan.md`. Use this structure:

```markdown
# Plan: <Feature Name>

> Spec: [docs/<feature-name>/spec.md](<relative-path-to-spec>)

## Status Dashboard

| # | Chunk | Blocks | Branch / Commit | Auto Tests | Verify | Simplify | Review | Human |
|---|-------|--------|-----------------|:----------:|:------:|:--------:|:------:|:-----:|
| 1 | [Schema](chunks/01-schema.md) | 2, 3 | — | ⬜ | ➖ | ⬜ | ⬜ | ⬜ |
| 2 | [Event triggers](chunks/02-event-triggers.md) | 3 | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 3 | [Feed API](chunks/03-feed-api.md) | 4 | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 4 | [Email delivery](chunks/04-email-delivery.md) | — | — | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

**Legend:** ⬜ pending · ✅ passed · ❌ failed · ⚠️ incomplete · ➖ N/A

**Workflow order per chunk:** Auto Tests → Verify → Simplify → Review → Human

**Columns:**
- **Auto Tests**: unit/integration tests passing (red-green-refactor, committed clean)
- **Verify**: E2E check — real curl or browser automation against a live system; ➖ if no external surface
- **Simplify**: code has been through a simplify/refactor pass
- **Review**: correctness review — bugs, edge cases, error handling
- **Human**: developer has manually signed off

**On failure:** ❌ in Verify, Simplify, or Review requires fixes before proceeding, or the plan
needs updating if scope has changed. Do not mark Human ✅ while any prior column is ❌.

## Branching Strategy

<one paragraph: recommended approach and why>

## Chunks

### 1. Schema
<2–3 sentences: what this chunk covers, what "done" looks like>
[→ Detailed TDD plan](chunks/01-schema.md)

### 2. Event Triggers
...
```

The "Branch / Commit" column starts empty (—). It gets filled in as work proceeds — with a branch
name, worktree path, or commit hash, whatever is appropriate.

The status columns track:
- **Auto Tests**: unit/integration tests passing in CI or locally
- **LLM Verify**: LLM ran the code and confirmed correct behavior — mark ➖ if no external surface
- **Human**: the developer has manually verified the behavior works as expected
- **Simplify**: the code has been through a simplify/refactor pass
- **Review**: the code has been through an automated review pass

## Step 5: Write the Chunk Sub-Plans

For each chunk, invoke the TDD chunk planner to produce a detailed implementation plan. See
`sub-skills/tdd-chunk.md` for how to do this.

Each sub-plan lives at `docs/<feature-name>/chunks/<NN>-<chunk-name>.md`. The main plan links to
each one.

You can write all sub-plans immediately after the main plan, or write them on demand as each chunk
is started. If the user seems ready to start implementing, write them all now. If they want to
review the main plan first, write the sub-plans lazily.

## Keeping the Plan Current

The plan.md is a living document. Update it as work progresses:

- When work on a chunk begins, fill in the Branch / Commit column
- When a status changes (tests pass, human verifies, etc.), update the emoji in the dashboard
- If scope changes during implementation, update the chunk description and sub-plan

The plan is done when every cell in the dashboard is either ✅ or ➖.
