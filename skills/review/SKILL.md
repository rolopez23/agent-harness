---
name: review
description: >
  Reviews staged changes or a branch diff for bugs, missed edge cases, and unhandled error
  conditions. Runs three parallel reviewers — standard correctness, exhaustive path tracing,
  and adversarial — then merges findings and reports reviewer validity.
  Trigger when the user says "review this", "check for bugs", "what did I miss", "look for
  edge cases", or when the plan dashboard's Review column needs to be updated.
---

# Review

Three independent reviewers run in parallel against the same diff. Each brings a different
lens. Findings may overlap, contradict, or be unique — that's the point. All findings are
surfaced; each is triaged before acting on it.

The three sub-skills are in `sub-skills/`:
- `standard.md` — correctness: bugs, edge cases, error handling, contract violations
- `edge-case-hunter.md` — exhaustive path tracing: every unhandled branch/boundary, JSON output
- `adversarial.md` — cynical: at least 10 issues, including speculative ones

## Two Run Modes

Review can be invoked two ways. Both are valid — they have different gates.

- **Workflow mode** — invoked as part of a plan-driven step. Runs after Simplify, before
  Understand, against the step's staged code. The prior-step gate below applies.
- **Standalone mode** — invoked ad-hoc on staged changes, a PR, or a branch diff outside
  of any plan. No gate; skip straight to Step 1. Use this when reviewing someone else's
  PR or any one-off correctness pass.

Detect the mode by looking for a plan at `docs/<feature>/plan.md` that references the
files in the diff. If one exists and the diff matches a step in it, you're in workflow
mode. Otherwise, standalone.

## Prior-Step Gate (workflow mode only)

When running as part of a plan, review follows Simplify in the chain:
Auto Tests → Verify → Simplify → **Review** → Understand → Human. Before doing any work,
confirm the prior columns are complete.

1. Find the row for the current step in `docs/<feature>/plan.md`.
2. The **Auto Tests** column must be ✅.
3. The **Verify** column must be ✅ or ➖ (N/A). A verification report must exist at
   `docs/<feature>/verify/<step>-*.md` if Verify is ✅.
4. The **Simplify** column must be ✅. A simplify report must exist at
   `docs/<feature>/simplify/<step>-*.md`.

**If any prior column is ⬜ or ❌:** Stop and say which one. For example: "Simplify has not
been run for this step — run `/simplify` first. Review runs against the simplified code so the
findings are about the code that will actually ship, not an intermediate version." Do not proceed.

In standalone mode, skip this gate entirely — there is no plan to gate against, and the
caller has decided to run review directly.

## Step 1: Gather Context

```bash
git diff --cached          # staged changes
# or for a branch:
git diff main...HEAD
```

Also read:
- Every file touched in the diff (bugs are often visible only in context)
- `docs/<feature>/spec.md` if it exists — Success Criteria and Interfaces sections

## Step 2: Dispatch All Three in Parallel

Spawn three subagents in the same turn. Give each:
1. The full diff text
2. The spec content (if found)
3. Their sub-skill instructions from `sub-skills/<reviewer>.md`

Do not wait for one to finish before starting the others.

**Subagent prompt template:**

```
You are running a code review. Follow the instructions in the sub-skill exactly.

## Sub-skill instructions
<contents of sub-skills/<reviewer>.md>

## Diff
<git diff output>

## Spec (if available)
<spec content, or "No spec found">
```

## Step 3: Merge Findings

Once all three complete, compile the report. Include every finding — do not pre-filter.
The triage step is for the human, not for the reviewer.

For edge-case-hunter's JSON output, convert each entry to a finding line:
```
- **<location>** — <trigger_condition> → <potential_consequence> · fix: `<guard_snippet>`
```

## Step 4: Triage

For each finding, assign one of:
- **Valid** — real issue, should be fixed
- **Speculative** — plausible but unconfirmed; worth noting
- **Dismissed** — false positive or out of scope; note why

The human makes final triage calls, but pre-triage obvious false positives with a brief
reason so the human doesn't have to stop and investigate them.

## Output Format

Save to `docs/<feature>/reviews/<step-name>-<YYYY-MM-DD>.md`. Determine `<feature>` from
the plan path (e.g., `docs/eval-results-display/plan.md` → `eval-results-display`).
If no plan exists, use `docs/reviews/<branch-name>-<YYYY-MM-DD>.md` as fallback.

```markdown
## Review: <branch or "staged changes">
## Date: <date>

---

### Standard Review

#### Bugs
- **<file>:<line>** — <finding> · `[Valid | Speculative | Dismissed: <reason>]`

#### Edge Cases
- ...

#### Error Handling
- ...

#### Contract Violations
- ...

---

### Edge Case Hunter

- **<file>:<line>** — <trigger> → <consequence> · fix: `<guard>` · `[Valid | Speculative | Dismissed: <reason>]`

---

### Adversarial

1. **<file>:<line>** — <finding> · `[Valid | Speculative | Dismissed: <reason>]`
2. ...

---

## Reviewer Validity

| Reviewer | Findings | Unique | Overlap | Verdict |
|---|---|---|---|---|
| Standard | N | N | N | Useful / Redundant / Noisy |
| Edge Case Hunter | N | N | N | Useful / Redundant / Noisy |
| Adversarial | N | N | N | Useful / Redundant / Noisy |

**Notes:** <anything notable about this run — e.g. "adversarial found 3 real issues standard missed",
"edge case hunter was redundant given the simplicity of this diff", etc.>
```

The **Reviewer Validity** table is the learning artifact. Over time it shows which reviewers
pull their weight on which types of changes. A reviewer that is consistently "Redundant" on
small diffs may not be worth running there; one that is consistently "Noisy" on UI changes
is worth noting.

## Update the Plan (MANDATORY)

**You MUST update plan.md immediately after this skill completes — not later, not batched.**
Update the Review column in plan.md:
- **All findings dismissed or clean** → ✅
- **Valid findings raised** → ❌ — address findings (fix or explicitly accept) before Human
  sign-off. Re-run review after fixes.
