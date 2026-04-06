# Harness

Skills and workflows for a standard agent development harness.

## Install

Run the install script from the root of any repo you want to onboard:

```bash
/path/to/harness/install.sh
```

Or target a specific directory:

```bash
/path/to/harness/install.sh ~/repos/my-project
```

This will:

- Copy all skills into `.claude/skills/`
- Create `AGENTS.md` and `CLAUDE.md` if they don't exist, or add missing sections if they do

Then start a Claude Code session — the skills are immediately available as `/commands`.

## Skills

| Skill                       | Invoke                         | Purpose                                                 |
| --------------------------- | ------------------------------ | ------------------------------------------------------- |
| initialize                  | `/initialize`                  | Write or update context files with skills reference     |
| problem-spec                | `/problem-spec`                | Define what is and isn't being solved                   |
| plan                        | `/plan`                        | Break a spec into testable steps with readiness gate    |
| verify                      | `/verify`                      | E2E check against a live system                         |
| simplify                    | `/simplify`                    | Clean up staged code                                    |
| review                      | `/review`                      | Find bugs and missed edge cases                         |
| pr-interactive-walkthrough  | `/pr-interactive-walkthrough`  | File-by-file walkthrough with understanding assessment  |
| learn-from-mistakes         | `/learn-from-mistakes`         | Log corrections after sign-off                          |
| frontend-design             | `/frontend-design`             | Build distinctive, production-grade frontend UI         |
| systematic-debugging        | `/systematic-debugging`        | Root-cause-first 4-phase debugging process              |
| dispatching-parallel-agents | `/dispatching-parallel-agents` | Split independent tasks across parallel subagents       |
| skill-creator               | `/skill-creator`               | Create, test, and iterate on new skills                 |
| next-react-boot             | `/next-react-boot`             | Scaffold a Next.js 16 / React 19 / Tailwind v4 frontend |
| python-psql-boot            | `/python-psql-boot`            | Scaffold a Python / FastAPI / PostgreSQL backend        |

## Workflow

```
/problem-spec  →  /plan  →  TDD loop  →  /verify  →  /simplify  →  /review  →  /pr-interactive-walkthrough  →  human sign-off  →  /learn-from-mistakes
```

## Acknowledgements

This harness builds on ideas and prompts from several excellent open-source projects. Thank you to:

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** — structured agent workflows and methodology
- **[superpowers](https://github.com/obra/superpowers)** — powerful Claude Code skill patterns
- **[agent-skills](https://github.com/addyosmani/agent-skills)** — curated collection of reusable agent skills

We're grateful to those authors for sharing their work.
