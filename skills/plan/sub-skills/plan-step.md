# Plan Step

This sub-skill produces a fine-grained, red-green-refactor implementation plan for a single step.
It is invoked from within the plan skill for each step in the main plan.

## Input

- The step name and description from the main plan
- The spec (for interface and schema context)
- Any dependencies this step has on previous steps (so you know what already exists)

## Output

A markdown file at `docs/<feature-name>/steps/<step-name>.md` structured as a sequence of
red-green-refactor cycles, each ending in a commit.

**Naming convention:** Use the E2E feature behavior the step delivers, not a number.
Name it after what the user or system can do when this step is done:

```
docs/notifications/steps/schema.md
docs/notifications/steps/event-triggers.md
docs/notifications/steps/feed-api.md
docs/notifications/steps/email-delivery.md
```

Not what the code does internally — what the feature does externally.

## The Workflow

Each cycle is one full red-green-refactor loop:

1. **Write the test(s)** — describe what you're about to implement in test form. Run the suite.
   The new tests must fail (red) before you write any production code. If a test passes before
   you write the code, it's not testing anything — revise it.
2. **Write the code** — write the minimum production code to make the failing tests pass. Run
   the suite again. All tests must be green.
3. **Refactor** — clean up if needed. Run the suite again. Still green.
4. **Commit** — commit everything (tests + code). All tests must be green at commit time.
   Never commit with red tests, skip tests, or mark tests pending to reach green.
   If you're stuck, stop and tell the user what you tried.

Repeat for the next cycle. Tests and code for a given behavior land in the same commit.

## Writing Good Cycles

Keep each cycle to one behavior. If going green would require more than ~30 lines of new
production code, split it. Good cycle boundaries:

- One model validation or scope
- One service method
- One controller action
- One job's core behavior
- One integration point (wiring a callback, hooking a service)

Order cycles so each builds on what the previous committed:

1. Schema / data model — tests need something to run against
2. Core logic — pure behavior, tested in isolation
3. Integration wiring — connecting to controllers, jobs, callbacks
4. Edge cases and failure modes — after the happy path is solid

## Commit Rules

- All tests green → you may commit
- Any test red → you may not commit; fix it or ask for help
- Never skip, pend, or comment out a failing test to reach green
- After the final cycle, update plan.md: mark Auto Tests ✅ for this step

## LLM Verification

After all cycles are committed, if this step has an externally observable surface (an API
endpoint, a background job whose effect can be queried, a rendered page), describe how to verify
it by actually running the code — exact command and what a passing result looks like.

If there is no external surface (e.g. a pure migration, an internal helper), mark N/A and say why.

---

## Template

```markdown
# Step: <step-name>

> Part of: [plan.md](../plan.md) · Spec: [spec.md](../spec.md)

## What This Step Delivers

<2–3 sentences describing the E2E capability this step adds>

## Done When

<concrete, checkable condition — something you can observe or run>

## Cycles

### <behavior name>

**Test** — write these tests and confirm they fail:
- **<test name>**: <what it asserts> · setup: <any fixtures needed>

**Code** — <what to implement to make those tests pass, 1–2 sentences>

**Refactor** — <cleanup to do, or "none">

**Commit**: `<short commit message>`

---

### <next behavior name>

**Test** — write these tests and confirm they fail:
- **<test name>**: <what it asserts> · setup: <fixtures>

**Code** — <implementation>

**Refactor** — <cleanup or "none">

**Commit**: `<short commit message>`

---

<repeat for each cycle>

## LLM Verification

<command or sequence to run and what a passing result looks like>

— or —

**N/A** — <reason>
```
