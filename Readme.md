# Harness

Skills and workflows for a standard agent development harness, packaged as a **Claude Code plugin**.

## Install (plugin — recommended)

Add the marketplace, then install the plugin:

```
/plugin marketplace add rolopez23/agent-harness
/plugin install rl-as@agent-harness
```

Skills are then available **namespaced** — `/rl-as:plan`, `/rl-as:verify`, `/rl-as:initialize`,
… — in every project. The plugin also installs two hooks automatically:

- **verify-evidence** (PostToolUse) — blocks marking a step verified without real evidence
  (a curl command, a Playwright screenshot/video, or a DB check).
- **tone** (SessionStart + UserPromptSubmit) — injects the house tone every turn and the
  coding standards on coding-intent prompts. Toggle with `/rl-as:tone`.

Update or remove later with `/plugin update rl-as` / `/plugin uninstall rl-as@agent-harness`.

## Install (fallback — no plugin system)

If you don't use the plugin system, `install.sh` copies skills into `~/.claude/skills/` at the
user level, where they're invoked **un-namespaced** (`/plan`, `/verify`, …), and installs the
same hooks:

```bash
/path/to/harness/install.sh
/path/to/harness/install.sh --dir <path>      # alternate Claude dir (testing)
/path/to/harness/install.sh --with <skill>    # also install an optional skill (repeatable)
/path/to/harness/install.sh --with all        # install every optional skill
```

The fallback does not write global context files — run `/initialize` inside a project to add
the workflow + routing context there. Use one path or the other, not both (the hooks would
double-fire).

## Skills

Invoke with the `/rl-as:` prefix under the plugin (e.g. `/rl-as:plan`), or bare (`/plan`)
under the fallback install.

| Skill                       | Purpose                                                 |
| --------------------------- | ------------------------------------------------------- |
| initialize                  | Write or update a project's AGENTS.md/CLAUDE.md context |
| problem-spec                | Define what is and isn't being solved                   |
| plan                        | Break a spec into testable steps with readiness gate    |
| verify                      | E2E check against a live system                         |
| clean-code                  | Clean up staged code                                    |
| refactor                    | Restructure existing code with Fowler's catalog         |
| review-comprehensive        | Comprehensive review — bugs and missed edge cases       |
| pr-interactive-walkthrough  | File-by-file walkthrough with understanding assessment  |
| frontend-design             | Build distinctive, production-grade frontend UI         |
| systematic-debugging        | Root-cause-first 4-phase debugging process              |
| dispatching-parallel-agents | Split independent tasks across parallel subagents       |
| tone                        | Toggle the house tone / coding standards on or off      |
| skill-creator               | Create, test, and iterate on new skills                 |
| btw-pull-request            | Split unrelated changes into a clean PR                 |
| next-react-boot             | Scaffold a Next.js 16 / React 19 / Tailwind v4 frontend |
| python-psql-boot            | Scaffold a Python / FastAPI / PostgreSQL backend        |
| command-center              | Table of all Claude Code sessions — active, branch      |

## Workflow

```
/initialize  →  /problem-spec  →  /plan  →  TDD loop  →  /verify  →  /clean-code  →  /review-comprehensive  →  /pr-interactive-walkthrough  →  human sign-off
```

(Prefix each with `/rl-as:` when installed as a plugin.)

## Acknowledgements

This harness builds on ideas and prompts from several excellent open-source projects. Thank you to:

- **[BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)** — structured agent workflows and methodology
- **[superpowers](https://github.com/obra/superpowers)** — powerful Claude Code skill patterns
- **[agent-skills](https://github.com/addyosmani/agent-skills)** — curated collection of reusable agent skills

We're grateful to those authors for sharing their work.
