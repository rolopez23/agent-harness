# Boot contract

Fixed by the orchestrator before frontend and backend are built in parallel.
Both sides build against this; neither depends on the other being done.

## Ports and URLs

| Service | URL | Env var (consumer side) |
|---|---|---|
| Frontend (Next.js) | `http://localhost:3000` | `FRONTEND_URL` (backend, for CORS) |
| Backend (FastAPI) | `http://localhost:8000` | `NEXT_PUBLIC_API_URL` (frontend) |
| Postgres 16 | `localhost:5432`, user/pass/db `app`/`app`/`app` | `DATABASE_URL` |
| Postgres test DB | same server, db `app_test` | `TEST_DATABASE_URL` |

`DATABASE_URL=postgresql+asyncpg://app:app@localhost:5432/app`
`TEST_DATABASE_URL=postgresql+asyncpg://app:app@localhost:5432/app_test`

## API

All backend routes are prefixed `/api`.

### `GET /api/health`

Runs `SELECT 1` against the database.

| Case | Status | Body |
|---|---|---|
| DB reachable | 200 | `{"status": "ok", "database": "ok"}` |
| DB unreachable | 503 | `{"status": "degraded", "database": "unreachable"}` |

## CORS

Backend allows origin `FRONTEND_URL` (default `http://localhost:3000`).

## File ownership

| Path | Owner |
|---|---|
| `frontend/**` | frontend builder |
| `backend/**` | backend builder |
| repo root files, `docker-compose.yml`, `docker/**`, `docs/**` | orchestrator |

Builders never edit files outside their directory.
