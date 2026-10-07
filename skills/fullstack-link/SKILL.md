---
name: fullstack-link
description: >
  Link a Next.js frontend/ and a FastAPI backend/ into one runnable repo: shared contract,
  Postgres via docker compose, root npm scripts (setup, db:up, dev, test, smoke), env files,
  and an end-to-end check that the browser shows the backend's health. Trigger on "link
  frontend and backend", "wire up the stack", "make them talk", or as the contract + link
  phases of /fullstack-boot.
disable-model-invocation: true
version: "1.0.0"
---

# Fullstack Link

Two phases. **Contract** runs before the builders so they can work in parallel without
talking to each other. **Link** runs after both finish and proves the stack works end to
end. Templates live in `templates/` next to this SKILL.md.

## Phase A — Contract (before builders)

The repo root, `docker/` and `docs/` belong to whoever runs this phase. Builders never
edit them.

1. Copy `templates/contract.md` → `docs/boot/contract.md`. Adjust ports only if
   3000/8000/5432 are taken (`lsof -nP -iTCP:<port> -sTCP:LISTEN`).
2. Copy `templates/docker-compose.yml` and `templates/docker/initdb/` (creates `app_test`).
3. Copy `templates/gitignore` → `.gitignore`.

The contract fixes: ports, env var names, `/api` prefix, the `GET /api/health` 200/503
body shape, CORS origin, and file ownership. **Change the contract first, then the code.**

## Phase B — Link (after builders)

1. **Root scripts.** Copy `templates/package.json` (replace `{{APP_NAME}}`), then
   `npm install -D concurrently@latest`.

   | Script | Does |
   |---|---|
   | `setup` | root + frontend `npm install`, backend `uv sync`, `env:init` |
   | `env:init` | copy `.env.example` → `backend/.env`, `frontend/.env.local` if missing |
   | `db:up` / `db:down` | `docker compose up -d --wait db` / `down` |
   | `db:migrate` | `alembic upgrade head` |
   | `dev` | `concurrently -k` backend + frontend |
   | `test` | backend pytest, then frontend vitest |
   | `smoke` | curl `/api/health` (fails on non-2xx) and the frontend |

2. **Env.** `npm run env:init`. Confirm `git check-ignore backend/.env frontend/.env.local`.
3. **Database.** Probe Docker without hanging:
   ```bash
   curl -s --max-time 5 --unix-socket /var/run/docker.sock http://localhost/_ping  # "OK"
   ```
   - OK → `npm run db:up && npm run db:migrate`.
   - Exit 28 / no socket → Docker is wedged or off. Tell the user to restart Docker
     Desktop; continue in **degraded mode** (below). Never call bare `docker` while
     unsure: it can block forever, and macOS has no `timeout`.
4. **Run.** `npm run dev` in the background; poll until both answer:
   ```bash
   for i in $(seq 1 30); do curl -sf -o /dev/null localhost:3000 \
     && curl -sf -o /dev/null localhost:8000/openapi.json && break; sleep 1; done
   ```
5. **Verify end to end.**
   - `npm run smoke`: exit 0 with DB up; with DB down it fails on the 503, which is expected.
   - CORS preflight from `http://localhost:3000` returns `access-control-allow-origin`.
   - **Browser** (Playwright/Chrome MCP): open `http://localhost:3000`, wait for the
     status text. DB up → `Backend: ok · Database: ok`. DB down →
     `Backend: degraded · Database: unreachable`. Check console errors; the only
     acceptable one in degraded mode is the 503.
   - `npm test`. DB up → integration test **passes**. DB down → it **skips** with a reason.
6. **Stop.** Kill dev processes; confirm 3000 and 8000 are free.
7. **Docs.** Fill the project's `AGENTS.md` Stack section (stack table, contract link,
   root commands) and `Readme.md` Getting started (`setup` → `db:up` → `dev`).
8. **Commit** on a branch. Message states what was verified and what wasn't.

### Done means

| Mode | Required evidence |
|---|---|
| Full | Browser shows `ok · ok`, smoke exit 0, integration test passed |
| Degraded (no Docker) | Browser shows `degraded · unreachable`, CORS ok, unit tests pass, integration skipped with reason. **Report it as not verified against Postgres** and list the exact commands to finish once Docker is back. |

## Gotchas

| Symptom | Fix |
|---|---|
| `docker info` hangs forever | Daemon wedged. Use the `_ping` probe above. Restart (macOS, with the user's OK): `osascript -e 'quit app "Docker"'`, wait for exit, `open -a Docker`, poll `_ping` until `OK`. Kill leftover hung `docker` CLI processes first. |
| `.playwright-mcp/` appears in `git status` | Browser MCP output; `gitignore` template ignores it. |
| Ports already bound after a run | `concurrently -k` kills siblings; still `pkill -f "uvicorn main:app"` / `"next dev"` if a run was interrupted. |
| Browser shows `Backend: unreachable` but curl works | CORS: `FRONTEND_URL` ≠ the page origin (e.g. `127.0.0.1` vs `localhost`). |
