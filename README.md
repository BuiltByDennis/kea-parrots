# Kea Parrot — Specification Index

**Product:** Kea Parrot — a web-first (responsive + PWA) social discovery and
micro-entertainment platform. Launch market: Ghana, starting with university
students. Nearby / Global / Trending feeds, anonymous or attributed text posts,
polls, and exactly three micro-games (QuickMind, This or That, Mystery Word).
No direct messaging, follower system, live streaming, or payments in the MVP.

**Repo status:** specification documents only. **No prototype exists**
(confirmed 2026-11-20) and no code has been written yet. Product P0 is a
greenfield foundation phase, not a prototype-to-production audit.

**Stack (agreed):** Next.js (App Router) + TypeScript + Tailwind CSS + shadcn/ui
+ Zod · Supabase (PostgreSQL + Auth + Realtime + Storage) + PostGIS · Vercel ·
Sentry · modular monolith (no microservices, no mandatory Redis/queue in MVP).

**Former working name:** MOMENT (superseded 2026-11-20 by owner decision).
Each spec file keeps that note once, in its header. No other MOMENT remains.

---

## The 8 specification documents

| Doc ID | File | What it is |
|---|---|---|
| KEA-FND-000 | `kea-parrot foundation` | Product & startup strategy: vision, moat, roadmap, monetisation, go-to-market |
| KEA-PRD-001 | `prd for kea-parrot` | Master PRD v1.1 — single source of truth for product and engineering |
| KEA-SAD-001 | `sad for kea parrots` | System Architecture Document (target baseline) |
| KEA-DBS-002 | `kea parrot dbs` | Database Design & Security Specification (27 tables) |
| KEA-UX-003 | `ui-ux` | UI/UX Implementation Specification |
| KEA-API-004 | `API and realtime specification` | API & Realtime Specification (65 endpoints, 12 events) |
| KEA-TPR-005 | `TESTING & PRODUCTION` | Testing & Production Readiness Specification |
| KEA-RDY-006 | `PRODUCTION READINESS prd` | Prototype-to-Production Readiness PRD — acceptance gates PR-01–PR-16 |

Filenames are unchanged from v1.0 (history-preserving). Cite documents by their
KEA-* IDs, not by filename. Each file carries a v1.1 header block and a
"Restructure note — 2026-11-20" listing what was resolved in that file.

---

## Canonical decisions (2026-11-20, owner: Dennis)

Restructured 2026-11-20 under decisions D-01–D-22. The full decision text lives
in the restructure working notes; this is the binding summary.

- **D-01 Name: Kea Parrot.** Doc IDs are KEA-* (above). Repo root is `kea-parrot/`.
- **D-02 Age: 16+ for MVP.** Users aged 16–17 are included; no adult-only
  content in the MVP; Ghana Data Protection Act 2012 (Act 843) / DPC review is
  still required before public launch. No parental-consent mechanism is
  specified — legal-review item (see Open Decisions).
- **D-03 Guests: browse + vote + play, limited time (Guest Session Rule).**
  A guest is an unauthenticated visitor with a server-issued guest-session
  token, not an account. Guests may browse public discovery, vote in polls,
  and play the 3 games — for **60 minutes from the guest session's first vote
  or game start**, ending on browser close, whichever is first. Guests may NOT
  post, comment, react, join communities, or report. One vote per poll per
  guest session; guest votes are counted; guest scores are not saved to a
  profile and do not appear on leaderboards; nothing transfers to a new
  account on registration. Rate limits apply per guest session + IP.
- **D-04 Prototype: not built.** All "existing system" audit language is
  re-scoped to greenfield foundation. Preservation rules (no destructive ops,
  no disabling RLS, no inventing requirements) apply from Product P1 onward.
- **D-05 Phase numbering — two tracks, never bare "Phase N":**
  Product track (KEA-PRD-001): **P0 Foundation, P1 Core MVP, P2 Private Beta,
  P3 Public Launch, P4 Commercialization, P5 Expansion.** Footprints, Mystery
  Drops, community challenges, leaderboards, referral, achievements,
  collectibles, progression, personalization are all **P3**.
  Readiness track (KEA-RDY-006): **R0–R10.** Testing steps T0–T11 map into
  R0–R10 (T11 Monitoring folds into R8 Observability). API steps 0–9 and UI
  steps 0–8 are sub-plans with mapping tables to R-phases in their own files.
- **D-06 Severity: P0–P3 only.** P0/P1 block release; P2 needs a planned fix
  and approval before release; P3 may be deferred with documented acceptance.
  (Former P4 cosmetic is now P3.)
- **D-07 CI gates (merged, in order):** 1 dependency install · 2 formatting ·
  3 linting · 4 type checking · 5 unit tests · 6 component tests ·
  7 integration tests · 8 API tests · 9 database & RLS tests ·
  10 production build · 11 security & dependency scans ·
  12 migration validation · 13 deployment checks ·
  14 post-deployment smoke tests · 15 required approval gates.
  A failed critical gate blocks the release.
- **D-08 Environments: 4** — local development, automated testing (ephemeral,
  CI-run), staging, production. Separate credentials per environment.
- **D-09 Definition of Done: one canonical list** — KEA-RDY-006 §17 (28
  checkboxes, merged 2026-11-20). Other files carry only their own view of it
  plus this reference, never a competing DoD.
- **D-10 Repo tree (canonical):** `kea-parrot/` with `apps/web/` (incl.
  `modules/<12 domains>/`), `apps/worker/` (only if approved workloads need
  it), `packages/{database, shared-types, validation, ui, analytics}`,
  `infrastructure/{migrations, policies, functions, jobs, monitoring}`,
  `docs/{PRD, ARCHITECTURE, DATABASE, SECURITY, API, ADR/, TESTING}`,
  `tests/{unit, integration, e2e, security}`, `scripts/`, `.github/`,
  `package.json`, `README.md`.
- **D-11 Vote replacement:** registered users may change a vote while a poll
  is open (one active submission, atomic replacement); guests may not change
  or remove a vote (one final submission). Results always come from stored votes.
- **D-12 Endpoints:** `PATCH /api/v1/me` = account fields only;
  `PATCH /api/v1/profiles/me` = public profile fields only; notification
  preferences canonical at `GET/PATCH /api/v1/me/notification-preferences`;
  `/me/preferences` covers non-notification preferences only.
- **D-13 Games: exactly 3 at launch** — QuickMind (5 questions/round),
  This or That, Mystery Word.
- **D-14 Challenges: NOT in MVP** — Product P3 scope.
- **D-15 Social rooms: REMOVED** as a requirement (unscoped idea; do not build).
- **D-16 "Ghost Notes + Vibe Check": DROPPED** — undefined, no requirements.
- **D-17 Content expiry:** MVP posts are persistent; no expiry infrastructure
  in P1; expiry is designed in P2 with temporary content.
- **D-18 Role storage:** `user_roles` table (user_id → auth.users.id, role
  enum registered/moderator/administrator/super_administrator, granted_by,
  granted_at, revoked_at). `profiles` has NO role column. Roles resolve
  server-side only, never from client claims; no self-assignment. RLS policy
  matrix has 5 role columns including Super Administrator.
- **D-19 ERD / store completeness:** DB ERD includes `analytics_events`,
  `notification_preferences`, `user_roles`, and FKs `polls.post_id`,
  `posts.community_id`, `communities.location_id`; polymorphic refs are
  validated in trusted app logic. SAD §8.1 lists all 27 tables.
- **D-20/21** Naming sweep + v1.1 headers and restructure notes (see above).
- **D-22 Nothing invented:** the numbers in Open Decisions below were NOT
  filled in during this restructure.

### What was removed, and why it stays removed

Social rooms, "Ghost Notes + Vibe Check", and MVP challenges had no
requirements (or contradicted the Master PRD). They are recorded in their
source files as removed/unscoped 2026-11-20. Re-adding any of them needs a
new owner decision with requirements attached — not a silent re-insertion.

---

## Open Decisions register (TBD — do not invent)

These were explicitly left open by the specs and by this restructure. Each
needs an owner decision before its phase, not during it.

| # | Decision | Owner | Needed before |
|---|---|---|---|
| OD-1 | Poll ↔ post linkage (`polls.post_id` nullable — always attached or independent?) | Dennis | Product P0 |
| OD-2 | Poll-option mutation after votes received | Dennis | Product P1 (polls) |
| OD-3 | Enum vs text for status/visibility fields; final SQL naming conventions | Dennis | Product P0 (migration 001) |
| OD-4 | Per-relationship FK `ON DELETE` behaviour (no blanket CASCADE) | Dennis | Product P0 (migration 001) |
| OD-5 | Post / comment character limits | Dennis | Product P1 (social) |
| OD-6 | Poll option limits, expiry defaults | Dennis | Product P1 (polls) |
| OD-7 | Trending-score coefficients / thresholds | Dennis | Product P1 (discovery) |
| OD-8 | Nearby search radius; location precision, SRID, retention | Dennis | Product P1 (discovery) |
| OD-9 | Game scoring weights, difficulty, clue count, attempt limits, timing rules | Dennis | Product P1 (games) |
| OD-10 | Page-size defaults / max; rate-limit thresholds (incl. guest sessions) | Dennis | Product P1 (API) |
| OD-11 | Upload size / type limits (storage use cases — text-only MVP) | Dennis | Product P1 (if any upload is approved) |
| OD-12 | Notification event categories + retention | Dennis | Product P1 (notifications) |
| OD-13 | Account-deletion lifecycle: grace period, delete vs anonymise vs retain | Dennis | Product P1 (accounts) |
| OD-14 | Moderation / audit / analytics / location retention periods | Dennis | Product P1 |
| OD-15 | RPO / RTO, backup frequency + retention, restore-test evidence | Dennis | Readiness R9 |
| OD-16 | Load targets (concurrent users, RPS), performance/alert thresholds, uptime SLO | Dennis | Readiness R8 |
| OD-17 | Password policy, session lengths, lockout / MFA | Dennis | Product P1 (auth) |
| OD-18 | Design tokens: brand colours, typography, light/dark mode, animation language | Dennis | Product P1 (UI) |
| OD-19 | Analytics / email / push / moderation-service vendors; OAuth providers | Dennis | Product P1 (as needed) |
| OD-20 | Payment provider / architecture (Phase 4 commercialization blocker) | Dennis | Product P4 |
| OD-21 | Parental-consent / 16–17 handling under Act 843 (legal review) | Dennis + counsel | Before public launch |
| OD-22 | Dependency versions to pin (Next.js, React, Node, TypeScript, Supabase) + test framework + CI platform | Dennis | Product P0 |
| OD-23 | Guest-session token transport/storage (cookie vs header, signing) | Dennis | Product P0 |
| OD-24 | Session transport / cookie strategy (verify against pinned Supabase + Next.js versions) | Dennis | Product P0 |
| OD-25 | Readiness PR-01 wording ("Repository audit") in a greenfield R0 — conscious owner sign-off that it means the foundation audit | Dennis | Readiness R0 |

---

## How to use these specs

1. Read this README first, then KEA-PRD-001 (Master PRD).
2. Never cite a bare "Phase N" — use Product P-N or Readiness R-N (D-05).
3. Never invent a value from the Open Decisions register to make a build
   pass. Flag it, propose, get approval (KEA-PRD-001 §2.2).
4. The API route list (KEA-API-004 §12), response examples, and realtime
   channel names are the proposed canonical contracts for the greenfield
   build — verify them as the P0 migration/route plan, do not duplicate them.
5. RLS is mandatory on every exposed table; never disable it to fix a query.
   Roles come from `user_roles` only (D-18).

## Restructure history

- **v1.0 (2026-11-20):** 8 spec files as first written. Contradictions present
  (see the 2026-11-20 implementation readiness report: 18 contradictions,
  56+ open decisions).
- **v1.1 (2026-11-20):** contradictions resolved under D-01–D-22 above;
  this README added. No code was written in this pass. Next step is
  Product P0 Foundation: pin versions (OD-22/23/24), close OD-1/3/4, write
  migration 001, skeleton repo (D-10), CI (D-07), and provision dev/staging/
  production environments (D-08).
