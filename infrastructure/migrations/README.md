# Migrations

Database migrations for Kea Parrot, per KEA-DBS-002 §9 (Migration Standards).

## Naming and order

Files are named `YYYYMMDDHHMMSS_description.sql` and apply in filename
order. Never edit a migration that has already been applied to any shared
environment (dev/staging/production) — write a new migration instead.
Prefer additive changes (nullable column → backfill → validate → add
constraint); destructive operations (DROP TABLE/COLUMN, TRUNCATE, PK-type
change, removing RLS, broad permission changes, data deletion) need explicit
approval (KEA-DBS-002 §9.5).

## How to apply

Against Supabase (the database runs there, not in this repo):

- Preferred: Supabase CLI — `supabase db push` from the linked project
  (applies pending files in `infrastructure/migrations/` in order, and
  records them in the migration history).
- Or: run the file in the Supabase Dashboard SQL editor, or with
  `psql "$DATABASE_URL"` using the **direct** connection string (port 5432).
- Apply to a clean database first, then to a seeded staging database
  (KEA-DBS-002 §9.2 step 7), and run the verification checklist at the foot
  of each migration before touching production. Never reset/recreate a
  production database.

## Migration 001 — `20261120213000_initial_schema.sql` (FINAL v1.0)

Initial greenfield schema: **27 tables** (KEA-DBS-002 §4, incl. `user_roles`),
**13 Postgres ENUM types**, **25 explicit indexes** (+ 11 auto-created by
UNIQUE constraints = 36 total), **14 `updated_at` triggers** (one shared
`set_updated_at()` function), PostGIS + pgcrypto extensions.

Decisions applied (owner-confirmed 2026-11-20): OD-1 = A (`polls.post_id`
NULLABLE — polls may be standalone or attached to a post), OD-3 = A
(Postgres ENUMs for closed value sets), OD-4 = A (`ON DELETE RESTRICT`
everywhere except the two auth-identity CASCADEs: `profiles.id` and
`user_roles.user_id` → `auth.users.id`). `guest_session_id` (nullable,
exactly-one-of `user_id`/`guest_session_id` CHECK) is included on
`poll_votes` and `game_sessions` per D-03 (Guest Session Rule) — approved
as part of the same package; it is an extension beyond the spec's field
lists (decision sheet item X-1).

**RLS:** this migration enables Row Level Security on all 27 tables and
creates **zero policies**. That is deliberate and is the safe starting
state — with RLS on and no policies, anon/authenticated roles get no access
at all. The app cannot read or write anything until the policies migration
(built from the KEA-DBS-002 §8.3 matrix, tested per role per §15.2) lands.
`service_role` bypasses RLS.

**No seed data** in migration 001. The 3 approved games (QuickMind,
This or That, Mystery Word) are seeded by a separate Product P1 migration
once their rules/scoring are approved (OD-9).

## Verification after applying

Run the post-apply checklist at the foot of the migration file and expect:
27 tables, 13 enums, 36 indexes, 14 triggers, 0 tables with RLS off,
0 policies. Then RLS policy tests per role (§15.2) and poll-integrity
tests (§15.4) before any production approval.
