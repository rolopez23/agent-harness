---
name: review
description: >
  Reviews staged changes or a branch diff for bugs, missed edge cases, and unhandled error
  conditions. Reports findings only — does not modify code. A clean bill of health is a
  completely valid and common output.
  Trigger when the user says "review this", "check for bugs", "what did I miss", "look for
  edge cases", or when invoked as a subagent before committing. Also trigger when the plan
  dashboard's Review column needs to be updated.
---

# Review

You are reviewing code that is staged for commit (or on a branch) looking for three things:
bugs, missed edge cases, and unhandled error conditions. You do not touch the code. You report
what you find.

## Get the Diff

```bash
git diff --cached          # staged changes
# or for a branch:
git diff main...HEAD
```

Read the diff. Then read the full context of every file touched — a bug is often visible only
when you see how the changed code interacts with its surroundings.

Also read the spec if one exists (`docs/<feature>/spec.md`) — the Success Criteria and
Interfaces sections tell you what the code is supposed to do and what contracts it must honor.

## The Bias

**A clean review is not a failure.** If the code is correct, say so. Do not manufacture
findings to appear useful.

Only raise an issue if you can articulate: what the bug is, under what conditions it occurs,
and what the incorrect behavior would be. Vague concerns ("this might be slow", "consider
adding logging") are not bugs — leave them out.

## What to Look For

### 1. Bugs
Logic that produces the wrong result for valid inputs. Common patterns:

- Off-by-one errors (boundary conditions, zero vs. empty, first vs. last)
- Wrong operator (`<` vs `<=`, `=` vs `==`, `&&` vs `||`)
- Mutation where a copy was intended (or vice versa)
- Order-dependent operations that aren't guaranteed to run in order
- State that isn't reset between uses

### 2. Missed Edge Cases
Valid inputs or states the code doesn't handle correctly. Work through the spec's Success
Criteria and ask: does this code actually satisfy each one? Then ask what the code does when:

- The input is empty, nil, zero, or negative
- The input is at the maximum or minimum boundary
- A collection has one element vs. many
- A dependent record doesn't exist
- The same operation is called twice (idempotency)
- Concurrent requests arrive simultaneously (race conditions in shared state)

### 3. Unhandled Error Conditions
Failure modes that aren't caught or that produce the wrong response. Look for:

- External calls (network, DB, file system) with no error handling
- Exceptions that bubble up to the wrong layer
- Partial writes — code that modifies multiple things and can fail halfway through, leaving
  inconsistent state
- Missing authentication or authorization checks on new endpoints
- Input validation gaps — what happens if a required field is missing or malformed?

### 4. Contract Violations
Code that doesn't match the interfaces defined in the spec:

- API response shape differs from the documented contract
- A side effect the spec requires (e.g. "atomically marks all unread") isn't atomic
- A guarantee the spec makes (e.g. "within the same transaction") isn't upheld

## Output Format

```markdown
## Review: <branch or "staged changes">
## Date: <date>

### Bugs
- **<file>:<line>** — <what the bug is, when it occurs, what goes wrong>

### Edge Cases
- **<file>:<line>** — <what input or state triggers it, what happens>

### Error Handling
- **<file>:<line>** — <what can fail, what happens when it does>

### Contract Violations
- **<file>:<line>** — <which contract, how it's violated>

---
Clean bill of health.
```

Only include sections that have findings. If there are no findings at all:

```markdown
## Review: <branch or "staged changes">
## Date: <date>

Clean bill of health.
```

Do not include suggestions for improvements, style feedback, or performance observations —
those belong in the simplify skill. This review is strictly about correctness.

## Save the Output

Save the report to `docs/reviews/<branch-name>-<YYYY-MM-DD>.md` (use `git branch --show-current`
for the branch name). If no `docs/` directory exists, save to `.claude/reviews/` instead.
Tell the user where the file was saved.

## Update the Plan

If run as part of a plan chunk, update the Review column in plan.md:
- **Clean bill of health** → ✅
- **Findings raised** → ❌ — findings must be addressed (fixed or explicitly accepted) before
  Human sign-off. If fixing requires scope changes, update the plan. Re-run review after fixes.
