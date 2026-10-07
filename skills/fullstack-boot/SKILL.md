---
name: fullstack-boot
description: >
  Orchestrate a full-stack boot end to end: preflight, contract, parallel subagents that
  build frontend/ (next-react-boot) and backend/ (python-psql-boot), then link and verify
  in the main thread (fullstack-link), then harvest skill friction. Trigger on "boot the
  full stack", "boot frontend and backend", "new full-stack app", "/fullstack-boot".
disable-model-invocation: true
version: "1.0.0"
---

# Fullstack Boot (orchestrator)

```
Preflight ─► Contract ─┬─► sa: frontend (next-react-boot) ─┐
                       └─► sa: backend  (python-psql-boot) ─┴─► Link + verify ─► Friction ─► Report
              main thread                 parallel                      main thread
```

The main thread owns the repo root, `docker/`, `docs/`, linking and verification.
Subagents own exactly one directory each. The contract is what lets them run in
parallel without talking to each other.

**Skill paths.** Sibling skills sit next to this one: `../next-react-boot/SKILL.md`,
`../python-psql-boot/SKILL.md`, `../fullstack-link/SKILL.md`. Resolve them to
**absolute paths** before putting them in subagent prompts. Boot skills are
`disable-model-invocation`, so subagents **read** the SKILL.md; they can't invoke it.

Record wall-clock start/end of each phase for the report.

## 0. Preflight (one batched shell call, every probe bounded)

| Check | Command | If it fails |
|---|---|---|
| Tools | `node -v; npm -v; uv --version` | Stop; tell the user what to install. |
| Registries | `curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://registry.npmjs.org/next` (and `https://pypi.org/simple/fastapi/`) | Stop: builders need network. |
| Docker | `curl -s --max-time 5 --unix-socket /var/run/docker.sock http://localhost/_ping` | Don't stop. Ask the user to restart Docker Desktop; continue. Link runs degraded if it's still down. |
| Ports | `lsof -nP -iTCP:3000 -iTCP:8000 -iTCP:5432 -sTCP:LISTEN` | Pick free ports; write them into the contract. |
| Git | `git status --short; git branch --show-current` | Dirty or on main → create a branch (`boot/scaffold`). |

Never run bare `docker …` or `npm view` in preflight: both can hang, and macOS has no
`timeout`.

## 1. Contract

Run `fullstack-link` **Phase A**: contract, compose, initdb, `.gitignore`. Also settle,
in one question if unknown: app name, one-line tagline, and whether there are backend
entities now (default: none → health-only).

## 2. Build (parallel)

Dispatch both in **one message**, both `run_in_background: true`,
`subagent_type: general-purpose`, using the prompts in
[builder-prompts.md](builder-prompts.md) with the placeholders filled in.

While they run, the main thread may only work on files it owns, e.g. draft the root
`package.json`. Do not touch `frontend/` or `backend/`.

**If a builder is stopped or fails:** a stopped agent can't be resumed. Inspect what it
left behind (`find <dir> -type f -not -path '*/node_modules/*'`), then dispatch a
**continuation** builder (`builder-prompts.md` → Continuation). It continues from the
existing files and does not start over. Ask the user first if they stopped it on purpose.

## 3. Link + verify

Run `fullstack-link` **Phase B** in the main thread. Use the builders' reported run/test
commands; reconcile with the contract. "Done" follows that skill's Full/Degraded table.

## 4. Friction harvest

Merge both builders' friction logs plus your own (preflight, link) into
`docs/boot/friction.md` in the project:

| # | Skill | What it said | What happened | Fix to skill text | Severity |

Then ask the user: apply these to the harness skills now? If yes: harness branch, edit
skills (and templates, copying from the verified project files), PR.

## 5. Report

- What runs, with the URLs, and the mode (Full or Degraded) with the evidence.
- Commands: `npm run setup`, `db:up`, `dev`, `test`, `smoke`.
- Phase timing table (preflight, contract, build, link, friction) plus the slowest
  step and why.
- Not verified, and the exact commands to finish it.
- Commit hash.

## Rules

- Don't let a builder edit outside its directory or commit. The main thread commits once
  after link.
- Don't report success from a builder's word alone. Phase B re-runs tests and checks the
  browser.
- Don't skip the friction harvest. It's how the boot skills get faster next time.
