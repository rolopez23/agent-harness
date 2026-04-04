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
