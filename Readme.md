# Harness

Skills and workflows for a standard agent development harness.

## Install

Run the install script once — it installs at the **user level** (`~/.claude`), so the skills
apply to every project automatically:

```bash
/path/to/harness/install.sh
```

Options:

```bash
/path/to/harness/install.sh --dir <path>      # install into an alternate Claude dir (testing)
/path/to/harness/install.sh --with <skill>    # also install an optional skill (repeatable)
/path/to/harness/install.sh --with all        # install every optional skill
```

This will:

- Copy all skills into `~/.claude/skills/` (pruning any that no longer exist in the harness)
- Create `~/.claude/AGENTS.md` and `~/.claude/CLAUDE.md`, or add missing sections if they exist
- Install the `verify-evidence` hook into `~/.claude/hooks/` and register it in
  `~/.claude/settings.json` (blocks marking a step verified without real evidence)

Then start a Claude Code session — the skills are immediately available as `/commands`. No
per-repo install needed.

## Skills

| Skill                       | Invoke                         | Purpose                                                 |
| --------------------------- | ------------------------------ | ------------------------------------------------------- |
| initialize                  | `/initialize`                  | Write or update context files with skills reference     |
| problem-spec                | `/problem-spec`                | Define what is and isn't being solved                   |
| plan                        | `/plan`                        | Break a spec into testable steps with readiness gate    |
| verify                      | `/verify`                      | E2E check against a live system                         |
| clean-code                  | `/clean-code`                  | Clean up staged code                                    |
| review-comprehensive        | `/review-comprehensive`        | Comprehensive review — bugs and missed edge cases       |
| pr-interactive-walkthrough  | `/pr-interactive-walkthrough`  | File-by-file walkthrough with understanding assessment  |
| frontend-design             | `/frontend-design`             | Build distinctive, production-grade frontend UI         |
| systematic-debugging        | `/systematic-debugging`        | Root-cause-first 4-phase debugging process              |
| dispatching-parallel-agents | `/dispatching-parallel-agents` | Split independent tasks across parallel subagents       |
| skill-creator               | `/skill-creator`               | Create, test, and iterate on new skills                 |
| next-react-boot             | `/next-react-boot`             | Scaffold a Next.js 16 / React 19 / Tailwind v4 frontend |
| python-psql-boot            | `/python-psql-boot`            | Scaffold a Python / FastAPI / PostgreSQL backend        |

## Workflow

```
/problem-spec  →  /plan  →  TDD loop  →  /verify  →  /clean-code  →  /review-comprehensive  →  /pr-interactive-walkthrough  →  human sign-off
```

## Acknowledgements

This harness builds on ideas and prompts from several excellent open-source projects. Thank you to:

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** — structured agent workflows and methodology
- **[superpowers](https://github.com/obra/superpowers)** — powerful Claude Code skill patterns
- **[agent-skills](https://github.com/addyosmani/agent-skills)** — curated collection of reusable agent skills

We're grateful to those authors for sharing their work.
