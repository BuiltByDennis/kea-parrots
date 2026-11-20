# ADR-001 — Pinned versions (Product P0)

- **Status:** Accepted 2026-11-20 (owner-approved pins).
- **Context:** KEA-PRD-001 §21.1 requires all package versions to be pinned
  through the lockfile. No prototype exists; this is a greenfield pin set.
- **Decision:** exact pins (no `^`/`~`/`latest`), registry-verified
  2026-11-20 at scaffold time:
  Next.js 16.4.6 · React 19.3.1 · React DOM 19.3.1 · Node 26.13.1
  (npm 11.20.0) · TypeScript 6.0.3 · Tailwind CSS 4.3.5 ·
  @tailwindcss/postcss 4.3.5 · @supabase/supabase-js 2.119.2 ·
  @supabase/ssr 0.12.7 · Zod 4.6.7 · Vitest 5.1.1 · Vite 8.3.8 ·
  @playwright/test 1.65.1 · ESLint 10.15.0 · eslint-config-next 16.4.6 ·
  @sentry/nextjs 11.16.0 · @types/react 19.3.0 · @types/react-dom 19.3.0 ·
  @types/node 26.6.6 · Prettier 3.10.1 · lucide-react 1.77.0.
  (`next`, `supabase-js`, `@sentry/nextjs` are one patch above the
  VERSIONS.md research floor — the re-check rule in W2: pin the newest
  16.4.x / 2.119.x / 11.16.x patch available at scaffold.)
- **Consequences:**
  - TypeScript is deliberately 6.0.3, NOT 7.x: TS 7.0 ships without a
    programmatic compiler API and breaks typescript-eslint (hence
    `eslint-config-next` / `npm run lint`) and `next build`. Revisit only
    when typescript-eslint states support for TS ≥ 7.1.
  - Tailwind v4 is CSS-first: tokens live in `apps/web/styles/tokens.css`
    (`@theme`); there is no `tailwind.config.ts` in this repo.
  - ESLint 10 is flat-config only: `apps/web/eslint.config.js`; no
    `.eslintrc.json`. `next lint` was removed in Next.js 16 — lint via
    the ESLint CLI (`npm run lint`).
  - Supabase: use the new publishable/secret API keys, not the legacy
    anon / service_role JWT keys (deprecated end of 2026).
  - shadcn/ui has no version to pin (copy-paste via CLI); see
    `apps/web/README.md`.
  - The lockfile (`package-lock.json`) is committed on day one;
    `npm ci` is the only install command in CI.
