---
name: next-react-boot
description: >
  Scaffold a Next.js 16 / React 19 / TypeScript / Tailwind CSS v4 frontend from scratch.
  Trigger when the user asks to bootstrap, scaffold, or create a new frontend, Next.js app,
  or React project. Also trigger when the user says "boot frontend", "new frontend",
  "create frontend", or "scaffold frontend".
disable-model-invocation: true
version: "1.0.0"
---

# Next.js + React Frontend Boot

Use this skill to scaffold a frontend that follows these exact patterns and conventions.
Do not deviate unless instructed.

## Stack

- **Next.js 16** (App Router, Turbopack)
- **React 19**
- **TypeScript**
- **Tailwind CSS v4**
- **Portless** for local dev URLs

## Project Structure

```
frontend/
├── app/
│   ├── layout.tsx       # Root layout — fonts, metadata, global CSS
│   ├── globals.css      # Tailwind import + CSS variables
│   └── page.tsx         # Home page
├── public/              # Static assets
├── next.config.ts       # Turbopack root scoped to frontend/
└── package.json
```

## Key Conventions

- All pages go in `app/` using the App Router file conventions (`page.tsx`, `layout.tsx`, `loading.tsx`, etc.)
- Tailwind is configured via `@import "tailwindcss"` in `globals.css` — no `tailwind.config.*` file needed
- `next.config.ts` sets `turbopack.root: __dirname` to scope Turbopack to the `frontend/` directory
- CSS variables for colors are defined in `:root` in `globals.css` and mapped to Tailwind tokens via `@theme inline`
- Fonts are loaded via `next/font/google` in `layout.tsx` and injected as CSS variables

## Dev Server

Run from repo root:
```bash
npm run dev:frontend
```

Or from `frontend/`:
```bash
npm run dev
```

Local URL (via Portless): `http://react-frontend.localhost:1355`

## Backend API

The backend runs at `http://server.localhost:1355`. All routes are prefixed with `/api/`.

To call the backend from the frontend:
```ts
const res = await fetch("http://server.localhost:1355/api/your-route");
```

## Scaffolding Steps

When bootstrapping, produce the following files in order:

1. `frontend/package.json` — dependencies: next, react, react-dom, typescript, tailwindcss, @tailwindcss/postcss
2. `frontend/tsconfig.json`
3. `frontend/next.config.ts` — set `turbopack.root: __dirname`
4. `frontend/app/globals.css` — `@import "tailwindcss"`, `:root` color variables, `@theme inline` mapping
5. `frontend/app/layout.tsx` — root layout with fonts via `next/font/google`, metadata, global CSS import
6. `frontend/app/page.tsx` — home page
7. `frontend/postcss.config.mjs` — use `@tailwindcss/postcss`

After scaffolding, run `npm install` inside `frontend/`.

## Feature Prompt Template

When starting a new feature or page, ask the user:

> **What I want to build:** [describe the feature or page]
>
> **Key constraints:**
> - Use the App Router — pages in `app/`, layouts in `layout.tsx`
> - Tailwind v4: use utility classes directly, no config file
> - Fetch data from the backend at `http://server.localhost:1355/api/`
> - Keep components in the same file unless they need to be reused
> - No extra dependencies unless necessary

## Common Gotchas

- **Missing native binding on install:** If you see `Cannot find module '@tailwindcss/oxide-darwin-arm64'`, run `rm -rf node_modules && npm install` inside `frontend/`
- **Turbopack scope:** `turbopack.root` is set to `__dirname` (the `frontend/` dir) — don't move `next.config.ts` up to the repo root
- **CORS:** The backend allows `http://react-frontend.localhost:1355` by default; override with `FRONTEND_URL` env var if needed
