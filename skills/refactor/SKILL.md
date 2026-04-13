---
name: refactor
description: >
  Restructures existing code for modularity and clarity by actively applying Martin Fowler's
  refactoring catalog. Distinct from `/simplify` — refactor is invasive and assumes the user
  wants the structure changed, while simplify is conservative and biased toward silence.
  Trigger when the user says "refactor this", "make this more modular", "this file is too
  big", "split this up", "extract X out of Y", "this needs restructuring", or asks for
  Fowler-style moves on existing code. Do NOT trigger as part of the per-step workflow —
  refactor is an explicit, user-invoked operation, not a workflow stage.
---

# Refactor

You are restructuring existing code to improve its modularity, cohesion, and clarity. You
are not adding features. You are not fixing bugs. You are changing the shape of the code so
that future work — by humans or LLMs — is easier and safer.

This skill is invasive by design. Where `/simplify` is biased toward silence, `/refactor` is
biased toward action: the user has already decided the structure needs to change, and your
job is to apply Fowler's catalog systematically.

## Hard Rules

1. **Tests are not yours to touch.** Production code can be restructured; tests stay. If a
   test must change to accommodate a refactor, stop and ask the human. Tests are the contract
   that proves the refactor preserved behavior — silently editing them defeats the point.
2. **No new behavior.** A refactor that adds a feature, fixes a bug, or changes an output is
   not a refactor — it's a feature change masquerading as one. Stop and split the work.
3. **Tests must be green before you start, after every move, and at the end.** A refactor
   you cannot prove preserved behavior is not a refactor; it is a rewrite.
4. **Chesterton's Fence applies to every removal.** See below.

## Chesterton's Fence — Mandatory Before Any Removal

> If you find a fence in the middle of a field and don't know why it's there, don't tear it
> down until you understand why someone put it up.

Before deleting *any* line, function, branch, file, parameter, or feature from the code,
you must articulate **why it was added**. "Why is it there" is more important than "is it
used right now." Code that looks dead is often:

- A guard against a real-world condition the tests don't cover
- A workaround for a downstream system's quirk
- A historical compromise from a migration that left scaffolding behind
- Dynamic-dispatch / reflection / config-string callers that grep won't find
- A safety net the original author added after a production incident

For each candidate removal, run this check:

1. **`git blame`** the lines and read the commit message that introduced them. What problem
   was being solved? Is that problem still real?
2. **`git log -S'<unique snippet>'`** — find every commit that touched these lines. Is there
   a bug fix in the history? A revert? A "do not remove" comment in a PR description?
3. **Search for callers** — not just direct calls, but string references, config values,
   reflection, dynamic imports, JSON keys that match field names, route registrations.
4. **Read the test that exercises this branch.** If a test exists, the test name usually
   names the reason. If no test exists for the branch you want to delete, that is itself
   a signal — either the branch is genuinely dead (in which case the test gap is a bug)
   or it's reachable in production but uncovered (in which case deleting it is unsafe).
5. **Articulate the original purpose in one sentence.** If you cannot, stop and ask the
   human. Do not delete on suspicion.

Only after you can name *why it was added* are you qualified to decide whether the reason
still holds. If the reason still holds, leave the code alone — find a different refactor.
If the reason no longer applies (the bug it guarded against is gone, the caller was
deleted, the constraint changed), you may remove it. Your commit message must say *which
reason no longer applies*, not just "remove dead code."

This rule applies to:
- Functions, classes, methods, fields
- Conditional branches and guard clauses
- Parameters and return-value variants
- Whole files and modules
- Configuration entries and feature flags
- Dependencies in package manifests

It does not apply to:
- Pure renames (the code stays, only the name changes)
- Mechanical extractions (moving code from one place to another without deleting it)
- Whitespace, formatting, and comment cleanup

## When to Use Refactor vs Simplify

| Situation | Skill |
|---|---|
| New code from a step that just turned green | `/simplify` |
| Existing code the user wants restructured | `/refactor` |
| "Is this the simplest version?" | `/simplify` |
| "This file is too big, split it" | `/refactor` |
| "Extract X out of Y" | `/refactor` |
| "Clean up the staged changes before commit" | `/simplify` |
| Reviewing a PR for tightness | `/simplify` |
| "Make this more modular" / "reduce coupling" | `/refactor` |
| "Move this from the controller into a service" | `/refactor` |

Rule of thumb: simplify *prunes*, refactor *reshapes*. If the user wants the file structure,
module boundaries, or class hierarchy to change, that is refactor. If they want the existing
shape kept but the code inside it tightened, that is simplify.

## Process

### Step 1: Decide Whether to Refactor At All

**Refactoring is not mandatory.** "Do nothing" is a valid, often correct, outcome of this
skill. Every refactor introduces risk — bugs slip in through Fowler moves that look safe,
test gaps surface only in production, behavior subtly drifts during a rename. The default
is to leave working code alone.

Before any moves, evaluate the cost/benefit honestly. Apply this test:

> **The degree of refactoring must match the degree of benefit.** A small benefit justifies
> a small refactor. A large refactor requires a large, named, observable benefit.

For the code in scope, answer:

1. **What is the concrete benefit?** Not "cleaner" or "more modular" — name an outcome.
   Examples of real benefits: "the next planned feature can land in one file instead of
   six," "the team has been confused by this naming three times in code review," "this
   class is the bottleneck blocking testability of the module," "this duplication has
   already caused two bugs."
2. **What is the risk?** Test coverage on the code in scope, complexity of the moves,
   number of callers, age of the code, presence of subtle behavior the tests don't pin
   down (timing, ordering, error shapes).
3. **Does the benefit outweigh the risk?** Be honest. "It will feel nicer" is not a
   benefit. "I have a hunch the design is wrong" is not a benefit. "We might need this
   later" is speculation.

| Benefit | Recommended action |
|---|---|
| None — the code works, nothing concrete to gain | **Do nothing.** Report "no refactor recommended" and exit. |
| Small / cosmetic — slightly clearer naming, minor duplication | A handful of safe mechanical moves (rename, extract variable). Stop there. |
| Moderate — unblocks one specific upcoming change, removes a real friction point | Targeted refactor: 3–10 moves, all narrowly scoped to the friction. |
| Large — module boundaries are wrong and blocking work, recurring bugs trace to the structure | Full refactor. Justify the scope explicitly and get human sign-off before starting. |

**If you cannot point to a concrete benefit, exit with no changes.** Output:

```
Refactor evaluation: no refactor recommended.

Scope evaluated: <files / module>
Reasoning: <one or two sentences — what you looked at, why no change is the right call>

The code in scope works, the tests cover it, and no concrete benefit was identified that
would justify the risk of moving things around. Run /refactor again if a specific friction
point appears (a bug pattern, a blocked feature, a recurring confusion).
```

This is a successful outcome, not a failure. A skill that always finds work to do is a
skill that creates risk to justify its own existence. The user invoking `/refactor` is
asking you to *evaluate*, not to refactor unconditionally.

**Bias toward smaller refactors when in doubt.** If the benefit could be unlocked by 3
moves *or* by 15 moves, pick the 3. The smaller refactor delivers most of the value at a
fraction of the risk. Save the larger restructuring for when the smaller version proves
insufficient — by then the case will be stronger and the risk easier to argue.

### Step 2: Confirm the Target and the Goal

Before touching anything, get explicit answers:

1. **What code is in scope?** A file? A module? A class? A whole subsystem? Refactor without
   a defined scope drifts into a rewrite.
2. **What is the goal?** "Make it more modular" is not a goal — it's a wish. Push for a
   verifiable goal: "split `UserService` into auth and profile concerns," "extract HTTP
   handling out of the domain model," "reduce `OrderProcessor` from one 400-line method to
   composed steps under 50 lines each."
3. **What stays the same?** Public API, observable behavior, file paths used by other
   callers, database schema. Get the human to name the invariants.

If any of these is unclear, stop and ask. A refactor with a fuzzy goal will be argued about
forever — there is no "done" condition.

### Step 3: Run the Tests First

```bash
<project test command>
```

All tests must be green before you start. If they are not, stop — fix the failing tests
first (or have the human fix them), then begin. Refactoring on a red baseline means you
cannot tell which red came from your changes.

Record the test count and runtime. After each move, you'll re-run and confirm the same
count is still green.

### Step 4: Identify the Refactoring Moves

Scan the code in scope for opportunities from the Fowler catalog (below). List the moves
you intend to apply, in order. Order matters: do mechanical moves first (rename, extract)
before structural moves (split class, move method) before deletions (which require
Chesterton's Fence checks).

Present the list to the human before executing. They may add, remove, or reorder.

### Step 5: Apply Moves One at a Time

For each move:

1. Apply the move
2. Run the tests
3. If green: commit this single move with a descriptive message
4. If red: revert immediately, do not debug further, report what broke

Never batch moves before testing. The whole point of small refactoring steps is that when
something breaks you know exactly which move broke it.

For deletions specifically: complete the Chesterton's Fence check (above) *before* applying
the move. Document the answer in the commit message.

### Step 6: Verify the End State

After all moves are applied:

1. Full test suite — green
2. Build / typecheck / lint — clean
3. The original goal from Step 2 — observably met
4. Public API and observable behavior — unchanged

If any of these fails, the refactor is not complete. Either fix the gap or revert the
last move and stop.

## Fowler's Catalog — Active Moves

Refactor uses these moves *actively*, not as suggestions. Apply when the conditions match.

### Composition

- **Extract Function** — a block of code with a clear single purpose inside a longer
  function. Extract it, name it after intent, leave the call site readable.
- **Inline Function** — a one-line wrapper that obscures more than it reveals. Inline it.
- **Extract Variable** — a complex expression in a conditional or return statement. Pull it
  into a named local that documents what it represents.
- **Inline Variable** — a temp that's used once and named no better than the expression it
  holds. Inline it.

### Naming and Structure

- **Rename Variable / Function / Class** — when the current name lies, is too generic, or
  doesn't say what the thing actually does. Renames are mechanical and safe — do them
  liberally before more structural moves.
- **Change Function Declaration** — reorder, add, or remove parameters. Use this to
  introduce a parameter object when the count climbs above 3.
- **Encapsulate Variable** — wrap direct field access in a getter/setter so future changes
  have one place to land.

### Splitting Things Up

- **Extract Class** — a class with two distinct concerns becomes two classes. The signal:
  some methods only touch one subset of fields; other methods touch the other subset.
- **Extract Module / Extract File** — same logic at file level. A 600-line file with two
  loosely coupled groups of functions becomes two files.
- **Split Phase** — a function that does parse → compute → format becomes three. The signal:
  the function's local variables fall into distinct lifetimes.
- **Replace Conditional with Polymorphism** — only when the conditional is truly stable and
  branches have grown to share infrastructure. Do not introduce class hierarchies for two
  branches.

### Reducing Coupling

- **Move Function** — a function that uses another module's data more than its own belongs
  in that other module. Move it.
- **Move Field** — same logic for data: fields cluster around the methods that use them.
- **Hide Delegate** — when callers chain through one object to reach another, give the
  intermediate object a method that returns the result directly. Cuts the dependency on the
  far object.
- **Remove Middle Man** — the inverse: when an intermediate adds nothing, callers should
  talk to the real object directly.

### Removing Things (Chesterton's Fence applies)

- **Remove Dead Code** — only after the fence check above. Document why the original purpose
  no longer holds.
- **Remove Setting Method** — when a field should be immutable after construction.
- **Remove Parameter** — when a parameter is never used in a non-trivial way. Check all
  callers and the type's history before removing.
- **Inline Class** — a class that does almost nothing collapses into its caller. Check that
  the caller is actually the only user.

## Modularity Principles

Refactor is steered by a small set of principles. When choosing between two moves, prefer
the one that improves these:

1. **High cohesion** — code in a module should be about one thing. The module name should
   describe the one thing without using "and".
2. **Low coupling** — modules should know as little about each other as possible. Prefer
   interfaces over concrete types, prefer arguments over global state, prefer pure
   functions over methods that touch external resources.
3. **Single responsibility** — a class or function changes for one reason. If two unrelated
   business reasons would force you to edit the same file, it has two responsibilities.
4. **Stable dependencies** — depend on things that change less often than you do. Domain
   models depend on the standard library, not on HTTP framework types.
5. **Layer discipline** — if the project has layers (domain / application / infrastructure
   or model / view / controller), code should not skip layers or invert the dependency
   direction. Domain code should not import HTTP framework types; views should not query
   the database directly.

When a refactor would improve one principle but worsen another, name the trade-off in the
commit message and let the human decide.

## Output Format

```markdown
## Refactor: <scope>
## Date: <date>
## Goal: <one-sentence statement from Step 2>

### Invariants Preserved
- Public API: unchanged
- Observable behavior: unchanged
- Tests: <N> tests, all green before and after

### Moves Applied
1. **<file>:<line>** — <Fowler move name>: <one sentence on what changed and why>
2. ...

### Removals (with Chesterton's Fence rationale)
- **<file>:<line>** — Removed `<thing>`. Original purpose: <why it was added>. Why removal
  is safe now: <which reason no longer applies>.

### Skipped
- **<file>:<line>** — <Fowler move name>: skipped because <reason — usually "couldn't
  satisfy Chesterton's Fence" or "would have changed observable behavior">.

### Result
Goal met. All tests green. Build clean.
— or —
Partial. <what's done, what's left, why stopped>.
```

## Save the Output

Save the report to `docs/refactor/<scope>-<YYYY-MM-DD>.md`. If the refactor is tied to a
named feature, use `docs/<feature>/refactor/<scope>-<YYYY-MM-DD>.md` instead.

Tell the user where the file was saved and link to the commits that contain the moves.

## Commit Discipline

One commit per move. Commit messages follow this shape:

```
refactor(<scope>): <Fowler move name> — <what>

Why: <the goal this move serves from Step 2>
[For removals: Original purpose: ... Why safe to remove now: ...]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

Do not bundle moves into one commit. Small commits make bisecting trivial when a refactor
turns out to have changed behavior in a way the tests didn't catch.
