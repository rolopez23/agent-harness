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

| Skill | Invoke | Purpose |
|---|---|---|
| initialize | `/initialize` | Write or update context files with skills reference |
| problem-spec | `/problem-spec` | Define what is and isn't being solved |
| plan | `/plan` | Break a spec into testable TDD chunks |
| verify | `/verify` | E2E check against a live system |
| simplify | `/simplify` | Clean up staged code |
| review | `/review` | Find bugs and missed edge cases |
| learn-from-mistakes | `/learn-from-mistakes` | Log corrections after sign-off |
| frontend-design | `/frontend-design` | Build distinctive, production-grade frontend UI |
| systematic-debugging | `/systematic-debugging` | Root-cause-first 4-phase debugging process |

## Workflow

```
/problem-spec  →  /plan  →  TDD loop  →  /verify  →  /simplify  →  /review  →  human sign-off  →  /learn-from-mistakes
```
