---
name: next-react-boot
description: >
  Scaffold a Next.js 16 / React 19 / TypeScript / Tailwind CSS v4 frontend from scratch,
  with Vitest + Testing Library, ESLint flat config, and a backend status indicator.
  Trigger when the user asks to bootstrap, scaffold, or create a new frontend, Next.js app,
  or React project ("boot frontend", "new frontend", "scaffold frontend"). Run standalone
  or as the frontend builder inside /fullstack-boot.
disable-model-invocation: true
version: "2.0.0"
---

# Next.js + React Frontend Boot

Scaffold `frontend/` from the tested files in `templates/` (next to this SKILL.md), then
verify. Templates were verified end to end on 2026-10-07. Do not hand-write what a
template already covers.

## Stack (tested versions, 2026-10-07)

Next.js 16.4 (App Router, Turbopack) · React 19.3 · TypeScript 6 · Tailwind v4.3 ·
Vitest 5 + Vite 8 + Testing Library 16 + jsdom · ESLint 9 (flat) + eslint-config-next 16.

Install `@latest`, record resolved versions in the final report. TS 6 and Vite 8 are
recent majors; if a major moved past the ones above, re-check the Gotchas.

## Inputs

| Input | Default when absent |
|---|---|
| Contract (`docs/boot/contract.md`) | Frontend `http://localhost:3000`; backend `NEXT_PUBLIC_API_URL` = `http://localhost:8000`. A contract wins. |
| App name / tagline | Ask once, or use the repo name and a one-line placeholder. |
| Owns repo root? | Standalone: may add root `.gitignore`. Under `/fullstack-boot`: touch `frontend/` only. |

**Portless is optional, not default.** Only use it if the user asks; then set
`NEXT_PUBLIC_API_URL` to the Portless backend URL and tell the backend its new
`FRONTEND_URL` for CORS.

## Layout

```
frontend/
├── app/{layout.tsx,page.tsx,globals.css}
├── components/BackendStatus.tsx (+ .test.tsx)   # health indicator, proves the link
├── lib/api.ts                                   # apiUrl(): reads NEXT_PUBLIC_API_URL
├── public/.gitkeep
├── .env.example                                 # NEXT_PUBLIC_API_URL=http://localhost:8000
├── next.config.ts                               # turbopack.root: __dirname
├── tsconfig.json  postcss.config.mjs  eslint.config.mjs
├── vitest.config.mts  vitest.setup.ts
└── package.json
```

## Steps

Work in `frontend/`. Tests before code (red → green). Templates ship the tests.

1. **Package.** Copy `templates/package.json` (replace `{{APP_NAME}}`). Then:
   ```bash
   npm install next@latest react@latest react-dom@latest
   npm install -D typescript @types/node @types/react @types/react-dom \
     tailwindcss @tailwindcss/postcss \
     eslint@9 eslint-config-next@latest \
     vitest @vitejs/plugin-react jsdom \
     @testing-library/react @testing-library/dom @testing-library/jest-dom
   ```
   `@testing-library/dom` is a peer of RTL 16; install it explicitly. Keep `eslint@9`
   until eslint-config-next supports the next major.
2. **Config.** Copy `tsconfig.json`, `next.config.ts`, `postcss.config.mjs`,
   `eslint.config.mjs`, `vitest.config.mts`, `vitest.setup.ts`, `.env.example`.
   Create `public/.gitkeep`.
3. **Tests first.** Copy `components/BackendStatus.test.tsx`. `npm test` must fail.
4. **App.** Copy `lib/api.ts`, `components/BackendStatus.tsx`, `app/*`. Replace
   `{{APP_NAME}}` and `{{APP_TAGLINE}}`. `npm test` → green.
5. **Next's `AGENTS.md`.** `next dev` (16.4+) writes `frontend/AGENTS.md` pointing agents
   at `node_modules/next/dist/docs/`. **Commit it** — it fits the nested-AGENTS.md
   convention and Next re-creates it if deleted. (Opt out: `agentRules: false` in
   `next.config.ts`.)
6. **Verify** (below).

## Conventions

- App Router: pages/layouts in `app/`. Server components by default; `"use client"` only
  where state/effects are needed.
- Tailwind v4: `@import "tailwindcss"` in `globals.css`; colors as `:root` variables mapped
  via `@theme inline`; no `tailwind.config.*`.
- Fonts via `next/font/google` as CSS variables in `layout.tsx`.
- Backend calls go through `apiUrl(path)` from `lib/api.ts`. Never hard-code a backend URL.
- Components stay in the file that uses them unless reused or unit-tested.
- No extra dependencies without a reason.

## Tests

- Vitest + jsdom + Testing Library. `"test": "vitest run"` (no watch in scripts).
- Mock network with `vi.stubGlobal("fetch", …)`; env with `vi.stubEnv`. Clean up in
  `afterEach` (`vi.unstubAllGlobals()`, `vi.unstubAllEnvs()`).
- `BackendStatus` covers: checking, 200 ok, 503 degraded, network error, env override.

## Verify

```bash
npm test && npm run lint && npx tsc --noEmit && npm run build
npm run dev &                                  # then poll, don't sleep blindly:
for i in $(seq 1 30); do curl -sf -o /dev/null localhost:3000 && break; sleep 1; done
curl -s localhost:3000 | grep -o '<title>[^<]*'
kill %1; lsof -nP -iTCP:3000 -sTCP:LISTEN      # port must be free
```

macOS has no `timeout`; use the retry loop.

## Report

Files tree · commands with pass/fail · resolved versions · **friction log** (where this
skill was wrong/ambiguous, with the concrete text fix).

## Gotchas

| Symptom | Fix |
|---|---|
| Vitest: `Failed to resolve import "@/…"` | `resolve: { tsconfigPaths: true }` in `vitest.config.mts` (Vite ≥8). Older Vite: `vite-tsconfig-paths` plugin. |
| `next lint` not found | Removed in Next 16. Use `"lint": "eslint ."` with the flat `eslint.config.mjs`. |
| ESLint can't load `eslint-config-next` via `FlatCompat` | eslint-config-next 16 exports flat arrays; spread `core-web-vitals` and `typescript` directly (see template). |
| `Cannot find module '@tailwindcss/oxide-darwin-arm64'` | `rm -rf node_modules package-lock.json && npm install`. |
| Turbopack resolves files from repo root | `turbopack.root: __dirname` in `frontend/next.config.ts`; don't move the config up. |
| Browser CORS error calling backend | Backend `FRONTEND_URL` must equal the exact frontend origin (scheme + host + port). |
| npm warns about install scripts (`fsevents`, `unrs-resolver`) not in `allowScripts` | Harmless; build and lint work. |
