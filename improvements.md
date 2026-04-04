# Improvements Backlog

Pending enhancements to the harness — skills to add, merges to do, structural changes.

---

## In Progress

### ~~TDD sub-skill (`skills/plan/sub-skills/tdd.md`)~~ ✅ Done
Iron Law, red-green-refactor, good/bad examples, red flags, verification checklist.
Referenced by `plan-step.md`. Source: `refernce/superpowers/skills/test-driven-development/SKILL.md`

---

## Skills to Pull In

### ~~verification-before-completion~~ ✅ Done
Merged into `verify/SKILL.md` as the "Core Rule" section.

### ~~dispatching-parallel-agents~~ ✅ Done

### ~~webapp-testing~~ ✅ Done
Added as `skills/verify/sub-skills/webapp-testing/`. Referenced from the Web / Browser Verification section of verify.

### subagent-driven-development
Orchestrator pattern: fresh subagent per task, spec-compliance review, then code-quality
review. More structured version of what the harness already does informally with agents.
Has sub-agent prompt templates (implementer, spec-reviewer, code-quality-reviewer).
**Source:** `refernce/superpowers/skills/subagent-driven-development/SKILL.md`
**Where it fits:** Standalone skill; would extend the plan workflow after `/plan` produces steps.

### using-git-worktrees
Isolated branch workspaces per feature. Systematic directory selection, safety verification
(.gitignore check), auto-detects project setup, verifies clean baseline before starting.
**Source:** `refernce/superpowers/skills/using-git-worktrees/SKILL.md`
**Where it fits:** Standalone skill; natural pre-step before executing a plan.

### mcp-builder
Full MCP server development guide — TypeScript (recommended) and Python, with reference
docs for best practices, tool naming, error messages, and an evaluation framework.
**Source:** `refernce/skills/skills/mcp-builder/SKILL.md`
**Where it fits:** Standalone skill; independent of the core dev workflow.

---

## Structural Improvements

### ~~Merge `verification-before-completion` into `verify`~~ ✅ Done

### `writing-plans` self-review → already done
Merged into `plan/SKILL.md` as Step 7. ✅

### Scope check in `problem-spec`
The scope-check pattern from `writing-plans` ("if this covers multiple independent
subsystems, split before planning") could also live in `/problem-spec` — catch it even
earlier before a plan is written.

---

## Naming / Convention Cleanup

### Update `AGENTS.md` workflow block to reference `steps/` path
The workflow comment block in AGENTS.md still says generic "docs/<feature>" — could be
more precise now that we have a canonical `docs/<feature>/steps/<step-name>.md` convention.

### `README.md` skills table is missing skill-creator
`skill-creator` is installed by `install.sh` but not listed in the README skills table.
