# Kea Parrot — Security baseline (Product P0)

The P0 security baseline. Each item is a gate for Product P1 work, not a
claim that the item is already implemented.

- [ ] Dependencies pinned exactly; lockfile committed; `npm ci` in CI.
- [ ] No secrets in the repo, in logs, or in chat. `.env.example` holds
      placeholders only; every real env file is gitignored.
- [ ] Service-role key server-only, never in a browser bundle, API
      response, log, or `NEXT_PUBLIC_` variable (KEA-SAD-001 §9.3).
- [ ] RLS enabled on every exposed table from migration 001; policies
      tested per persona before shipping (KEA-DBS-002 §8).
- [ ] Server-side authorisation on every privileged operation; a hidden
      frontend button is not an authorisation control.
- [ ] Server-side input validation (Zod) on every write; no raw DB errors,
      stack traces, or internal details in API responses.
- [ ] `reactStrictMode` on; `poweredByHeader` off.
- [ ] Sentry configured with no PII, tokens, passwords, or service-role
      keys in events.
- [ ] Four environments (local / automated testing / staging / production)
      with separate credentials; never point local/staging at production.
- [ ] CI gates (D-07) include security & dependency scans; a failed
      critical gate blocks the release.
- [ ] Ghana Data Protection Act 2012 (Act 843) / DPC review before public
      launch (legal review, owner + counsel — OD-21).
