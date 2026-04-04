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

### Upgrade `/review` — multi-layer adversarial review
Add two sub-skills modeled on BMAD's parallel reviewer pattern:
- `sub-skills/edge-case-hunter.md` — mechanically walks every branch/boundary, reports only
  unhandled paths as structured JSON; method-driven, not attitude-driven
- `sub-skills/adversarial.md` — cynical pass finding at least 10 issues; skeptical attitude
  regardless of how clean the code looks

Main `review/SKILL.md` runs both passes and merges findings.
**Source:** `bmad-review-edge-case-hunter`, `bmad-review-adversarial-general`

### Upgrade `/problem-spec` — stress-test pass
Add a final stage to `/problem-spec` that challenges the finished spec using:
- **Pre-mortem** — "Imagine this shipped and failed. What went wrong?"
- **Red-team** — steelman the strongest objections to the approach
- **Socratic** — probe any assumption that hasn't been explicitly validated

Spec doesn't finalize until it survives this pass.
**Source:** `bmad-advanced-elicitation`, `bmad-prfaq`

### Add readiness gate to `/plan`
Lightweight checklist at the end of Step 7 (self-review) verifying that spec, file map,
and step plans are internally consistent before handing off to implementation:
- Every spec requirement maps to a step
- Every file in the file map is touched by at least one step
- No step references a type, method, or file not defined elsewhere in the plan
**Source:** `bmad-check-implementation-readiness`

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

### Scope check in `problem-spec`
Add the scope-check pattern ("if this covers multiple independent subsystems, split before
planning") to `/problem-spec` so it's caught before a plan is ever written.

### Update `AGENTS.md` workflow block to reference `steps/` path
Be more precise now that we have a canonical `docs/<feature>/steps/<step-name>.md` convention.

### Add `skill-creator` to README skills table
It's installed by `install.sh` but not listed in README.
