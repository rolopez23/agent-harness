# TDD Chunk Planner

This sub-skill produces a fine-grained, red-green-refactor implementation plan for a single chunk.
It is invoked from within the plan skill (step 5) for each chunk in the main plan.

## Input

- The chunk name and description from the main plan
- The spec (for interface and schema context)
- Any dependencies this chunk has on previous chunks (so you know what already exists)

## Output

A markdown file at `docs/<feature-name>/chunks/<NN>-<chunk-name>.md` structured as a sequence of
red-green-refactor steps, each ending in a commit. There is no separate "tests to write first"
section — the tests are embedded in each step, written before the code for that step.

## The Workflow

Each step is one full red-green-refactor cycle:

1. **Write the test(s)** — describe what you're about to implement in test form. Run the suite.
   The new tests must fail (red) before you write any production code. If a test passes before
   you write the code, it's not testing anything — revise it.
2. **Write the code** — write the minimum production code to make the failing tests pass. Run the
   suite again. All tests must be green.
3. **Refactor** — clean up if needed. Run the suite again. Still green.
4. **Commit** — commit everything (tests + code). All tests must be green at commit time.
   No exceptions: do not commit with red tests, do not skip tests, do not mark tests pending to
   get to green. If you're stuck, stop and tell the user what you tried.

Repeat for the next step.

This is not a loop you run once at the end. Every single step goes through all four stages.
Tests and code for a given behavior land in the same commit.

## Writing Good Steps

Keep each step to one behavior. If making a step go green would require more than ~30 lines of
new production code, split it. Good step boundaries:

- One model validation or scope
- One service method
- One controller action
- One job's core behavior
- One integration point (wiring a callback, hooking a mailer)

Order steps so each one builds on what the previous step committed:
1. Schema / data model first (tests need something to run against)
2. Core logic (pure behavior, tested in isolation)
3. Integration wiring (connecting to controllers, jobs, callbacks)
4. Edge cases and failure modes (after the happy path is solid)

## Commit Rules

- All tests green = you may commit.
- Any test red = you may not commit. Fix it or ask for help.
- Never skip, pend, or comment out a failing test to reach green.
- After committing the final step of a chunk, update the plan.md status dashboard:
  mark Auto Tests ✅ for this chunk.

## LLM Verification

After all steps are committed, if this chunk has an externally observable surface (an API
endpoint, a background job whose effect can be queried, a rendered page), describe how to
verify it by actually running the code — the exact command or sequence and what a passing
result looks like. This is a live check, not an automated assertion.

If there is no external surface (e.g. a pure migration, an internal helper), mark it N/A and
say why.

---

## Template

Use this exact structure for every chunk sub-plan. Do not add a "Tests to Write First" section
or batch the tests separately — tests belong inside each step.

```markdown
# Chunk: <NN>. <Chunk Name>

> Part of: [plan.md](../plan.md) · Spec: [spec.md](../spec.md)

## What This Chunk Does

<2–3 sentences>

## Done When

<concrete, checkable condition — something you can observe or run>

## Steps

### Step 1: <name>

**Test** — write these tests and confirm they fail:
- **<test name>**: <what it asserts> · setup: <any fixtures needed>
- <add more tests if this step has multiple behaviors worth asserting>

**Code** — <what to implement to make those tests pass, 1–2 sentences>

**Refactor** — <cleanup to do, or "none">

**Commit**: `<short commit message>`

---

### Step 2: <name>

**Test** — write these tests and confirm they fail:
- **<test name>**: <what it asserts> · setup: <fixtures>

**Code** — <implementation>

**Refactor** — <cleanup or "none">

**Commit**: `<short commit message>`

---

<repeat for each step>

## LLM Verification

<command or sequence to run and what a passing result looks like>

— or —

**N/A** — <reason>
```
