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
