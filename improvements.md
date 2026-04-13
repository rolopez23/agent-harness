# Improvements Backlog

Pending enhancements to the harness — skills to add, merges to do, structural changes.

---

## Completed

- ✅ TDD sub-skill (`skills/plan/sub-skills/tdd.md`)
- ✅ verification-before-completion → merged into `verify/SKILL.md`
- ✅ dispatching-parallel-agents
- ✅ webapp-testing → `skills/verify/sub-skills/webapp-testing/`
- ✅ `writing-plans` self-review → merged into `plan/SKILL.md` as Step 7

---

## From BMAD Analysis

### ~~Upgrade `/review` — multi-layer adversarial review~~ ✅ Done
Three parallel sub-skills: standard, edge-case-hunter, adversarial. Orchestrator merges
findings, triages, and records reviewer validity for future reference.

### ~~Upgrade `/problem-spec` — stress-test pass~~ ✅ Done
Three parallel sub-agents (pre-mortem, red-team, socratic) run against the draft spec.
Findings are synthesized and used to re-interview the user before finalizing.

### ~~Add readiness gate to `/plan`~~ ✅ Done
Added as Step 8 in plan/SKILL.md — 6-item checklist before implementation handoff.

---

## Future Consideration

### subagent-driven-development
Orchestrator pattern: fresh subagent per task, spec-compliance review, then code-quality
review. Has prompt templates for implementer, spec-reviewer, and code-quality-reviewer agents.
**Source:** `refernce/superpowers/skills/subagent-driven-development/SKILL.md`

### using-git-worktrees
Isolated branch workspaces per feature. Systematic directory selection, .gitignore safety
check, auto-detects project setup, verifies clean baseline before starting.
**Source:** `refernce/superpowers/skills/using-git-worktrees/SKILL.md`

### mcp-builder
Full MCP server development guide — TypeScript and Python, with best practices, tool naming,
error message guidelines, and an evaluation framework.
**Source:** `refernce/skills/skills/mcp-builder/SKILL.md`

### ~~Scope check in `problem-spec`~~ ✅ Done
Addressed by Step 3 (Define the Boundary) in problem-spec and scope check in plan.

### ~~Update `AGENTS.md` workflow block to reference `steps/` path~~ ✅ Done

### ~~Add `skill-creator` to README skills table~~ ✅ Done

---

## From Learnings Log Analysis (gc-ai-takehome 2026-04-04 → 2026-04-05)

Each item lists: the recurring pattern, occurrences, and the proposed change. Parse one
at a time — the highest-leverage workflow items are at the top; skill-content items follow.

### Workflow gates and discipline

#### 1. Prior-step gate on every workflow skill (in progress)
**Patterns:** `workflow-steps-skipped` (5×), `verify-not-automatic` (3×), `verify-out-of-order` (1×), `plan-not-updated` (3×)
**Change:** Every skill in the workflow chain (`verify`, `simplify`, `review`, `pr-interactive-walkthrough`, `learn-from-mistakes`) must, when running as part of a plan, read `plan.md` and assert the prior column for the current step is ✅ or ➖ before doing any work. If not, refuse and tell the user which step to run first. Simplify already has this for Verify — generalize and replicate.

#### 2. Worktree / background-agent handoff (in progress)
**Patterns:** `agents-skip-workflow` (1×), `verify-not-automatic` (3×)
**Change:** Background/worktree agents cannot reliably run `/verify`, `/simplify`, `/review` themselves (different process, no plan visibility, no shared context). Add explicit handoff instructions to `plan-step.md`: when a step is implemented by a worktree agent, after merging the work back, the orchestrator MUST run V → S → R in order before marking the step done. The worktree agent's job ends at "tests green, work merged."

#### 3. Plan-update enforcement
**Patterns:** `plan-not-updated` (3×)
**Change:** "MANDATORY" language already exists in every skill but is still skipped. Stronger: each skill's final action is a literal grep/sed against `plan.md` to confirm its own column changed; if not, fail loudly. Or: a post-skill hook that diffs plan.md and complains if it's unchanged.

#### 4. Never commit a broken app
**Pattern:** `broken-app-committed` (1×, but high-severity user rule)
**Change:** Add to AGENTS.md: "An unworking environment at the end of any step is a code red. Never commit if the app is not working e2e — fix or stop and report."

#### 5. Feature-branch-before-code rule
**Pattern:** `committed-to-main` (1×)
**Change:** Add to AGENTS.md: before the first commit of a new feature, assert `git branch --show-current` is not main/master. Plan's branching strategy step should record the branch name and the workflow should refuse to commit until that branch exists.

#### 6. "Verification is the only proof" rule
**Pattern:** `verification-is-proof` (1×, philosophical)
**Change:** Add to `verify/SKILL.md` (top): review and simplify passing are not evidence of correctness. Only verification is. The agent must not communicate confidence in correctness based on review/simplify status alone.

### Simplify gaps

#### 7. TS `as` cast smell
**Pattern:** `unnecessary-type-cast` (3×)
**Change:** Add a check item to `simplify/SKILL.md`: any `as SomeType` in non-test code is a smell. Prefer Zod schema parse, type guard, or actual type narrowing. Same for `as HTMLInputElement` in tests — RTL queries return `HTMLElement`, the consuming API accepts it, the cast is dead weight.

#### 8. Re-run after subsequent fixes
**Pattern:** `simplify-not-rerun-after-fix` (1×)
**Change:** Add to `simplify/SKILL.md`: if code changed in this step's files after the last simplify pass, the pass is stale and must be re-run before Review can start.

#### 9. Implicit-when-obvious return types
**Pattern:** `typescript-style-mismatch` (1×)
**Change:** Add to `simplify/SKILL.md` (TS-specific section): for functions where the return type is self-evident from the body (predicates, simple validators), prefer implicit return types. Don't add `: boolean` to `isValid(x)`.

### Review gaps (review/sub-skills/standard.md)

#### 10. Accessibility checklist
**Pattern:** `accessibility-not-reviewed` (2×)
**Change:** Add an Accessibility section to `review/sub-skills/standard.md`: missing `aria-label` on `<section>`, missing `aria-expanded` on toggle buttons, `<div>`-based lists where `<ul>/<li>` is correct, missing `role="status"` / `aria-busy` on loading regions, color-only severity indicators. Frontend-cleanup has this for simplify, but review needs it too — review is the gate, simplify is the cleanup.

#### 11. RTL test antipatterns
**Pattern:** `rtl-query-antipattern` (1×), `brittle-style-assertions` (1×)
**Change:** Add to `review/sub-skills/standard.md`: tests using `document.querySelector` instead of RTL's `screen.getByRole` / `getByLabelText`; assertions on raw Tailwind class strings (`toContain('text-red-600')`) instead of semantic constants (`COLORS.fail`) or roles.

#### 12. Cross-boundary contract mismatch
**Pattern:** `cross-boundary-contract-mismatch` (1×)
**Change:** Add to `review/sub-skills/standard.md`: when a diff touches a frontend API call, grep for the route on the backend; when it touches a backend route, grep for callers in the frontend. Spec'd path vs implemented path must match. The tests on each side of the boundary will not catch this.

#### 13. Missing reset-after-action
**Pattern:** `missing-reset-after-action` (1×)
**Change:** Add to `review/sub-skills/standard.md`: any submit/save/post handler — does the relevant local UI state get cleared after success? Form fields, file inputs, optimistic state.

#### 14. Prompt bias / prompt token efficiency
**Patterns:** `prompt-bias-not-considered` (1×), `prompt-output-not-optimized` (1×)
**Change:** When a diff touches a system/user prompt sent to an LLM, add prompt-specific checks: scoring labels with strong plain-English bias (fair/unfair → fair/non-standard), output verbosity, token budget vs. realistic input size.

### Verify gaps

#### 15. Multi-`.env` preflight
**Pattern:** `env-config-mismatch` (3×)
**Change:** Before running any verification, enumerate every `.env*` file under the repo. For the process being verified, identify which one(s) it actually loads, and confirm the required keys are present *in the loaded file*. Don't assume the root `.env` is enough.

#### 16. Model constraint check
**Pattern:** `model-constraints-not-researched` (1×)
**Change:** When verifying any code that calls an LLM, look up the model's `max_tokens` limit before running. Don't downgrade mid-run; pick a model whose limits fit the realistic output size.

#### 17. CORS / browser-only verification paths
**Pattern:** `cors-not-tested` (1×)
**Change:** When the diff touches CORS, auth headers, or anything cross-origin, the verification *must* go through a real browser (Playwright). Test clients (httpx, fastapi TestClient) bypass CORS middleware and will pass even when production fails.

#### 18. SQLite vs Postgres divergence
**Pattern:** `sqlite-vs-postgres-divergence` (1×)
**Change:** When tests use SQLite and prod uses Postgres, verify against a real Postgres instance for: timezone-aware datetime vs `TIMESTAMP WITHOUT TIME ZONE`, JSON columns, case-sensitivity, integer types.

#### 19. Verify-script thrashing prevention
**Pattern:** `verify-script-thrashing` (2×)
**Change:** Add a pre-flight to `verify/SKILL.md` for ad-hoc scripts: identify CJS vs ESM, the working directory the project's tooling expects, and how env vars are loaded — *before* writing the script. Don't iterate on a thrashing script; stop and re-plan after the second failure.

#### 20. Sync-in-async detection
**Pattern:** `sync-in-async` (1×)
**Change:** Add to `simplify/SKILL.md` Python section: any synchronous SDK client called inside an `async def` blocks the event loop. Use the `Async*` variant.

### Walkthrough gaps

#### 21. Walkthrough calibration
**Pattern:** `walkthrough-calibration-inflated` (1×)
**Change:** Add to `pr-interactive-walkthrough/SKILL.md`: comprehension ratings should be calibrated against actual corrections needed in conversation. If the user corrected a concept, that file/concept cannot be rated High. Also: if a walkthrough question matches a code comment verbatim, it is not a real comprehension test.

#### 22. Walkthrough scope
**Pattern:** `walkthrough-scope-too-large` (1×)
**Change:** Add to `pr-interactive-walkthrough/SKILL.md`: the skill is calibrated for step-level granularity, not full milestones. If the diff covers more than ~6 file groups, split the walkthrough into per-step sessions.
