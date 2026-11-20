# Kea Parrot — Web app (Product P0 scaffold)

Next.js 16 App Router + TypeScript + Tailwind v4 + Supabase. P0 scaffold
only — no product features yet. See the repo-root `README.md` for the
spec index and decisions D-01–D-22, and `docs/ADR/` for decision records.

## Versions (pinned, registry-verified 2026-11-20)

Next.js 16.4.6 · React 19.3.1 · Node 26.13.1 · TypeScript 6.0.3 ·
Tailwind 4.3.5 · supabase-js 2.119.2 · @supabase/ssr 0.12.7 · Zod 4.6.7 ·
Vitest 5.1.1 · Playwright 1.65.1 · ESLint 10.15.0 · @sentry/nextjs 11.16.0.
Full table + warnings: `docs/ADR/001-pinned-versions.md`.
TypeScript is deliberately 6.0.3, NOT 7.x (7 has no compiler API and breaks
typescript-eslint / `next build`).

## Run locally

```sh
nvm use            # .nvmrc: 26.13.1
npm install        # root: installs workspaces, writes package-lock.json
cp .env.local.example .env.local  # copy .env.example (repo root) — fill in
                                 # values from the Supabase dashboard
npm run dev --workspace=kea-parrot-web   # http://localhost:3000
```

Environments (D-08): local, automated testing (ephemeral, CI-run), staging,
production — each with its own Supabase project and credentials. Never point
local/staging at production resources.

## Scripts (from `apps/web`)

`dev` / `build` / `start` / `lint` (`eslint .` — `next lint` was removed in
Next.js 16) / `typecheck` / `format` / `test` (Vitest) /
`test:unit|component|integration|api|db` / `test:e2e` (Playwright).

## shadcn/ui (no version to pin)

shadcn/ui is copy-paste component source, not a package — there is no
version in `package.json`. Add primitives in P1 with
`npx shadcn@latest init` / `add` (pass `--base radix` if Radix primitives
are wanted; the CLI now defaults to Base UI). Components are owned source
once copied in. Note: `lucide-react` ships no brand/social icons — use
inline SVGs for brand icons.

## Notes

- No `middleware.ts`: Next.js 16 renamed it to `proxy.ts`. No middleware /
  proxy is needed in P0 — do not create one.
- No PWA manifest / service worker (PWA install is Product P3).
- The only P0 page is the smoke-test stub at `/` and the health route at
  `/api/health` (`{ "ok": true }`).
