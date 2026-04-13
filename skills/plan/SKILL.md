---
name: plan
description: >
  Creates a structured implementation plan from a problem spec, breaking work into independently
  testable steps with dependency tracking and a living status dashboard.
  ONLY trigger this skill when a problem spec already exists at docs/<feature>/spec.md — if no spec
  is present, simpler ad-hoc planning suffices and this skill should not be used.
  Trigger on: "make a plan", "plan this out", "how should we implement this", "create an
  implementation plan", "break this into tasks", "what order should we build this in" — but only
  when a spec.md exists. If the user asks to plan something and there is no spec, tell them to run
  /problem-spec first.
---

# Plan Skill

You are creating a living implementation plan from a problem spec. The goal is to break the work
into steps that can be built, tested, and verified independently — and to track the state of each
step as the work proceeds.

## Before You Start

Locate the spec at `docs/<feature-name>/spec.md`. Read it fully. If it does not exist, stop:
"I need a problem spec before I can make a plan. Run /problem-spec first."

**Scope check:** If the spec covers multiple independent subsystems, suggest splitting into separate
plans before continuing — one plan per subsystem, each producing working, testable software on its
own. A plan that covers too much is worse than no plan.

## Step 1: Map the File Structure

Before decomposing into steps, map out which files will be created or modified and what each is
responsible for. This is where decomposition decisions get locked in — do it before writing tasks,
not during.

- Each file should have one clear responsibility
- Files that change together should live together; split by behavior, not by layer
- In existing codebases, follow established patterns unless a file has grown unwieldy enough that
  a split belongs in the plan

List the files explicitly:

```
Create:  src/models/notification.ts     — Notification data model
Create:  src/jobs/digest-sender.ts      — Background job: sends digest emails
Modify:  src/api/feed.ts (lines ~40–80) — Add notification feed endpoint
Test:    tests/models/notification.ts
Test:    tests/jobs/digest-sender.ts
```

This structure informs step decomposition. Each step should produce self-contained file changes
that make sense independently.

### Refactor Check Before Decomposition

Once the file map is written, look at the **Modify** entries — the existing files this work
will touch. If the plan will land non-trivial changes in files that are already large,
tangled, or have a known smell (long methods, mixed responsibilities, tight coupling to
things this work shouldn't depend on), pause and ask the user before continuing:

```
Before I decompose into steps, this plan will modify these existing files:

- <file 1> (~<lines> lines, <one-line observation>)
- <file 2> (~<lines> lines, <one-line observation>)
- ...

Some of these look like they'd be easier to change cleanly if they were refactored first.
Want me to kick off /refactor on <specific files> before we plan the new work? Refactoring
into a clean shape now avoids stacking new code on top of structural problems and having
to back-fill the cleanup later.

Yes / no / only on <subset>
```

**When to ask:**

- The plan will touch a single file in **3+ different steps** — that file is a coupling
  point and is likely to grow worse during this work
- A file slated for modification is **>300 lines**, or has a function the plan needs to
  edit that's >50 lines
- The plan needs to add behavior to a class that already has mixed responsibilities (e.g.,
  a `UserService` that also does email sending and audit logging)
- The plan will introduce a new concept that fits naturally in an existing module, but
  the existing module has no clean place to put it

**When NOT to ask:**

- The plan only **creates** new files (no Modify entries)
- **Create entries outnumber Modify entries by 5× or more** — this is mostly new work,
  the existing files are incidental, and refactoring them would be a detour
- The refactor would be larger than the feature itself — flag it as a separate piece of
  work in Open Questions, don't bundle them

The goal of refactoring is *to move faster*, not to slow down — so "we want to ship fast"
is a reason **to** ask, not a reason to skip the question. A clean shape is what makes the
next change cheap. Only skip when the refactor genuinely isn't on the path of this work.

If the user says yes, hand off to `/refactor` with the specific files and a one-sentence
goal ("make room for the upcoming notification feed feature"). When refactor finishes,
re-run Step 1 of this skill — the file map may have changed.

If the user says no, note it in the plan under Open Questions / Known Smells so it
doesn't get silently lost.

## Verification-First Planning

> "Your job is to deliver code you have proven to work."
> — [Simon Willison](https://simonwillison.net/2025/Dec/18/code-proven-to-work/)

Every step in the plan must define how it will be **proven to work** — not "should work", not
"tests pass", but concrete evidence: command output, database state, browser behavior, curl
responses. A step without a verification strategy is incomplete.

When decomposing steps, ask: "How will I prove this step works to someone who can't read the
code?" If you can't answer that, the step is either too abstract or missing an observable surface.

**Verification is not optional.** The plan-step template requires an LLM Verification section.
➖ (N/A) is only valid when there is genuinely no observable effect — not when verification is
merely inconvenient. Before marking ➖, exhaust all paths: database inspection, file output,
log checking, API responses, process side effects.

## Step 2: Decompose the Spec into Steps

Read the "What We Are Solving" and "Interfaces" sections. Using the file map from Step 1, identify
natural units of independently testable work.

A step is a unit of work that can be tested on its own. Good steps:

- Have a clear, observable outcome (something you can assert about)
- Map to a coherent layer or behavior (data model, API endpoint, background job, UI component)
- Are small enough that one person can hold the whole thing in their head
- Are large enough that testing them tells you something meaningful

Typical layers: data model → core logic → API/transport → integrations → UI. Name each step
after the E2E capability it delivers — what the user or system can do when it's done, not what
the code does internally. Use kebab-case:

```
schema → event-triggers → feed-api → email-delivery
```

Not `01-schema`, not `create-notification-table`. What does the feature do when this step is complete?

### Slice Vertically, Not Horizontally

Decompose by feature slice, not by architectural layer. The default failure mode is to write
a plan where step 1 = all schemas, step 2 = all API routes, step 3 = all UI — nothing is
shippable or verifiable end-to-end until the very last step lands.

- ❌ **Horizontal:** `schemas → api-routes → ui-components → wiring`. Each step compiles but
  none of them deliver an observable behavior on their own. Verify is forced to ➖ until the
  end, which means most of the workflow runs blind.
- ✅ **Vertical:** `upload-contract → list-contracts → review-contract`. Each step touches
  the schema, API, and UI needed for *one* user-visible capability and ends in something a
  human can actually try.

Prefer vertical slices unless the steps share so much foundation that horizontal is
genuinely simpler (rare, and usually only for the very first foundational step like an
auth scaffold). A vertical slice is verifiable on its own; a horizontal slice is not.

### Step Sizing

Every step in the plan should be **S or M**. Use this table to calibrate:

| Size | Files touched | Code added | Treat as |
|---|---|---|---|
| **XS** | 1 | < 30 lines | A *cycle* inside another step, not a standalone step. Merge it into a neighbor. |
| **S** | 1–3 | 30–100 lines | A normal step. One model + tests, one validator + tests, one focused UI component. |
| **M** | 3–6 | 100–300 lines | A normal step. One vertical slice of a small feature: one route + service + tests. |
| **L** | 6–10 | 300–600 lines | Acceptable **only** if it passes the 4-signal split check below and genuinely cannot be split. |
| **XL** | 10+ | 600+ lines | Always a planning failure. Split before adding to the plan. |

A single step that takes a feature all the way from model → API → UI is usually L or XL and
should be **multiple steps**, not one. The fact that it's "one feature" is not a reason to
keep it together — the verification gates work per step, and a step you can't verify halfway
through gives the workflow nothing to bite on.

### When to Split a Step Further

Even if a step looks reasonably sized, split it if **any** of these are true:

- The step would take more than ~2 hours of focused work
- The "Done When" condition needs more than 3 bullet points to express clearly
- The step touches two distinct subsystems (e.g., backend service *and* frontend page, or
  database *and* background worker) where each could be verified on its own
- The step's name needs an "and" to describe it (`upload-and-list`, `validate-and-store`)

A step that only reaches **L** because it fails one of these is hiding work. Split it. A
step that is L *and* passes all four signals — for example, a single service method that
genuinely needs six files of related fixtures and tests to verify — is the rare case where
L is the right size.

## Step 3: Map Dependencies

For each step, identify what it blocks and what blocks it. Be explicit: "step 3 cannot be
meaningfully tested until step 1 is complete" is a blocking dependency. "step 4 can be built
in parallel with step 3" is worth calling out.

Express as: step N blocks steps [X, Y]. An empty blocks list means the step is a leaf.

## Step 4: Choose a Branching Strategy

Based on step count, dependencies, and team size:

- **Single feature branch** — tightly coupled sequential steps; one branch, commits per step
- **Per-step branches** — few dependencies; steps can be reviewed and merged independently
- **Worktrees** — truly independent steps; work on them simultaneously without context-switching

State your recommendation and reasoning briefly. Record whatever the user chooses.

## Step 5: Write the Plan Document

Write to `docs/<feature-name>/plan.md`:

```markdown
# Plan: <Feature Name>

> Spec: [docs/<feature-name>/spec.md](relative-path-to-spec)

## Status Dashboard

| Step                                                      | Blocks          | Branch / Commit | Auto Tests | Verify | Simplify | Review | Understand | Human |
| --------------------------------------------------------- | --------------- | --------------- | :--------: | :----: | :------: | :----: | :--------: | :---: |
| [schema](steps/schema.md)                                 | event-triggers, feed-api | —      |     ⬜     |   ➖   |    ⬜    |   ⬜   |     ⬜     |  ⬜   |
| [event-triggers](steps/event-triggers.md)                 | feed-api        | —               |     ⬜     |   ⬜   |    ⬜    |   ⬜   |     ⬜     |  ⬜   |
| [feed-api](steps/feed-api.md)                             | email-delivery  | —               |     ⬜     |   ⬜   |    ⬜    |   ⬜   |     ⬜     |  ⬜   |
| [email-delivery](steps/email-delivery.md)                 | —               | —               |     ⬜     |   ⬜   |    ⬜    |   ⬜   |     ⬜     |  ⬜   |

**Legend:** ⬜ pending · ✅ passed · ❌ failed · ⚠️ incomplete · ➖ N/A

**Workflow order per step:** Auto Tests → Verify → Simplify → Review → Understand → Human

- **Auto Tests**: unit/integration tests passing (red-green-refactor, committed clean)
- **Verify**: Proof the code works ([ref](https://simonwillison.net/2025/Dec/18/code-proven-to-work/)) — real curl, browser automation, DB inspection, file output. ➖ only when genuinely no observable effect exists.
- **Simplify**: code has been through a simplify/refactor pass
- **Review**: correctness review — bugs, edge cases, error handling
- **Understand**: human passes `/pr-interactive-walkthrough` — all files rated Medium or High in the
  understanding assessment. Run with the step's commit range (before/after). Low on any file → ❌,
  follow up on low areas before sign-off
- **Human**: developer has manually signed off

**On failure:** ❌ in any column requires fixes before proceeding. Do not mark Human ✅ while any
prior column is ❌ without explicit user instruction.

**Prior-step gate (enforced by each skill):** Every workflow skill (`verify`, `simplify`,
`review`, `pr-interactive-walkthrough`, `learn-from-mistakes`) reads this dashboard before
running and refuses to start if the prior column for the current step is not ✅ or ➖. This
is a hard gate, not a suggestion — it exists because the workflow has been silently skipped
or reordered before. If a skill stops with a "prior step not complete" message, do not bypass
it; run the prior skill first.

---

## Branching Strategy

<one paragraph: recommended approach and why>

---

## Steps

### schema

<2–3 sentences: what this step delivers, what "done" looks like>
[→ Detailed plan](steps/schema.md)

### event-triggers

...
```

## Step 6: Write the Step Plans

For each step, write a detailed TDD implementation plan. See `sub-skills/plan-step.md`.
TDD rules (Iron Law, red-green-refactor, commit rules, red flags) live in `sub-skills/tdd.md`
— read it before implementing any cycle.

Each step plan lives at `docs/<feature-name>/steps/<step-name>.md`. The main plan links to
each one.

**No placeholders.** Every step in a sub-plan must contain what the engineer actually needs.
These are failures — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "handle edge cases" (without showing the code)
- "Write tests for the above" (without the actual test code)
- "Similar to Step N" (repeat the code — the engineer may read steps out of order)
- Steps that describe what to do without showing how

You can write all sub-plans immediately, or lazily as each step starts. If the user seems ready
to implement, write them all now. If they want to review the main plan first, write them on demand.

## Step 7: Self-Review

After writing the complete plan, check it against the spec with fresh eyes:

1. **Spec coverage** — skim each requirement in the spec. Can you point to a step that
   implements it? List any gaps and add tasks for them.
2. **Placeholder scan** — search for any of the failure patterns from Step 6. Fix them inline.
3. **Type/name consistency** — do method names, types, and property names used in later steps match
   what you defined in earlier steps? A function called `clearLayers()` in step 3 but
   `clearFullLayers()` in step 7 is a bug in the plan.

Fix issues inline — no need to re-review after fixing.

## Step 8: Readiness Gate

Before handing off to implementation, verify the plan is internally consistent. Every item
must pass — if any fails, fix it before proceeding.

- [ ] Every requirement in the spec maps to at least one step
- [ ] Every file in the file map (Step 1) is touched by at least one step
- [ ] No step references a type, method, or file not defined in the file map or an earlier step
- [ ] Dependency graph has no cycles — steps can be executed in the listed order
- [ ] Each step's "Done When" condition is observable and checkable
- [ ] No step depends on out-of-scope work from the spec

If all pass, tell the user: "Plan passes readiness gate — ready to implement." If any fail,
list failures and fix before continuing.

## Keeping the Plan Current

The plan is a living document. Update it as work progresses:

- When work on a step begins, fill in the Branch / Commit column
- When a status changes, update the emoji in the dashboard
- If tests fail or verification fails, check whether the plan missed something and update it
- If scope changes, update the step description and sub-plan

The plan is done when every dashboard cell is either ✅ or ➖.
