-- ============================================================================
-- Kea Parrot — Migration 20261120213000_initial_schema (FINAL v1.0)
-- Initial greenfield schema — 27 tables (KEA-DBS-002 §4, v1.1)
--
-- Status: FINAL v1.0 (2026-11-20). Decisions OD-1 = A, OD-3 = A, OD-4 = A
-- (owner-confirmed 2026-11-20); guest_session_id included per D-03
-- (approved as part of the same package). Do NOT run on production before
-- the RLS-policies migration lands (this file enables RLS with zero
-- policies, so anon/authenticated get no access until then) and before the
-- post-apply verification checklist at the foot of this file has been run
-- on staging (KEA-DBS-002 §9.2, §15.6).
--
-- Validation 2026-11-20: applied cleanly against PGlite 0.5.17
-- (PostgreSQL 18.7, WASM) + PostGIS 3.6, with an auth.users stub standing
-- in for what Supabase provides; first run OK and re-run OK (idempotent).
-- Verified: 27 app tables, 13 enums, 64 indexes, 14 triggers, 42 FKs
-- (40 RESTRICT + 2 CASCADE), RLS on for all 27 app tables, 0 policies,
-- updated_at trigger fires, RESTRICT blocks profile deletion with posts.
-- NOT yet run against real Supabase Postgres — first-run proof on staging
-- is still required before production.
--
-- Naming: YYYYMMDDHHMMSS_description.sql per KEA-DBS-002 §9.3.
-- Applied in filename order; never edit an applied migration — write a
-- new one instead.
--
-- Decisions OD-1 / OD-3 / OD-4 — all confirmed A by the owner on
-- 2026-11-20 (see decision sheet in the P0 working notes). Each decision
-- is marked in a comment below; the alternatives are recorded in the
-- decision sheet for the record and are NOT applied.
--
-- Decisions confirmed 2026-11-20 (OD-1 = A, OD-3 = A, OD-4 = A) and applied here:
--   OD-1 (poll<->post linkage): polls.post_id NULLABLE — a poll may be
--         standalone or attached to a post.
--   OD-3 (enum vs text): Postgres ENUM types for every closed value set
--         the spec actually lists (§5). Status/type columns the spec does
--         NOT enumerate stay TEXT (see "Underspecified" notes below).
--   OD-4 (FK ON DELETE): RESTRICT everywhere, EXCEPT the two auth-identity
--         CASCADEs listed in §2 (profiles.id and user_roles.user_id
--         -> auth.users.id). Never CASCADE on moderation/audit evidence
--         or votes.
--
-- RLS: ENABLE ROW LEVEL SECURITY is switched on for every app table below,
-- but NO policies are created in this migration. Policies are a later
-- migration (KEA-DBS-002 §8.3 matrix). NOTE: RLS enabled with no policies
-- denies ALL access to the anon/authenticated roles by default; the app
-- cannot read or write anything until the policies migration lands.
-- service_role bypasses RLS.
--
-- Nullability / type rule used in this draft (the spec gives SQL types for
-- profiles only, §4.1.1; every other table lists field names only):
--   * Fields the spec marks Required -> NOT NULL.
--   * Foreign keys and identifying fields -> NOT NULL unless the spec says
--     nullable. Descriptive/optional fields -> nullable.
--   * JSON-ish fields (configuration, metadata, properties, snapshots,
--     payloads, before/after state) -> JSONB.
--   * Approximate geography -> geography(Point, 4326) (PostGIS). The
--     approximation/precision rule itself is TBD (OD-8 / DB-OD-007); this
--     type does NOT decide it — app logic must round/coarsen before storing.
--   * Every draft type/nullability choice that the spec does not pin down
--     is flagged UNDERSPECIFIED in a comment and listed in the decision
--     sheet. Nothing is silently presented as spec-mandated.
--
-- Guest sessions (D-03 / D-11): the spec's field lists have no guest
-- identifier, yet guest votes and guest game sessions must be tied to the
-- guest session only, never to an account. This file therefore ADDS
-- guest_session_id (TEXT, nullable) to poll_votes and game_sessions, with
-- a CHECK that exactly one of user_id / guest_session_id is set. This is
-- an extension beyond the spec's field lists, approved 2026-11-20 as part
-- of the OD package (see decision sheet, item X-1).
--
-- No seed data in this migration. The 3 approved games (QuickMind,
-- This or That, Mystery Word) are seeded by a separate Product P1
-- migration once their rules/scoring are approved (OD-9).
--
-- Idempotency: idempotent table/index creation statements
-- (IF NOT EXISTS) and DO-block enum creation, so the file is re-runnable
-- on a partially migrated dev database. It is NOT a repair tool for a
-- half-applied production migration — follow KEA-DBS-002 §13.3 for recovery.
-- (Note: a grep for the table-creation statement counts exactly 27
-- matches in this file — the draft's 28th hit was its own comment line.)
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- §0. Extensions
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid() (KEA-DBS-002 §10.1)
CREATE EXTENSION IF NOT EXISTS postgis;   -- geography/geometry (KEA-DBS-002 §4.8)

-- ----------------------------------------------------------------------------
-- §1. ENUM types — OD-3 = A, confirmed 2026-11-20 (Postgres ENUM).
-- One DO block per type so the file is re-runnable. The alternative
-- (text + CHECK constraints) is recorded in the decision sheet and is
-- NOT applied: dropping this section would also change every column
-- type below from the enum name to text + CHECK.
-- ----------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE profile_visibility AS ENUM ('public', 'private');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE account_status AS ENUM ('active', 'restricted', 'suspended', 'pending_deletion', 'deleted');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE post_visibility AS ENUM ('public', 'private');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
-- UNDERSPECIFIED: the spec lists no values for posts.visibility (§4.2.1).
-- 'public'/'private' mirrors profile_visibility and is a DRAFT assumption.
-- Confirm, or supply the real set, before approval.

DO $$ BEGIN
  CREATE TYPE post_status AS ENUM ('published', 'hidden', 'removed', 'deleted');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE reaction_type AS ENUM ('like', 'funny', 'interesting', 'surprising');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE poll_selection_type AS ENUM ('single', 'multiple');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE poll_status AS ENUM ('draft', 'active', 'closed', 'removed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE game_session_status AS ENUM ('active', 'completed', 'abandoned', 'expired');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE community_membership_status AS ENUM ('active', 'pending', 'left', 'removed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE report_status AS ENUM ('open', 'under_review', 'action_taken', 'dismissed', 'escalated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE report_reason AS ENUM ('harassment', 'bullying', 'threats', 'hate_or_abuse', 'sexual_exploitation', 'spam', 'impersonation', 'dangerous_activity', 'privacy_violation', 'other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE location_source AS ENUM ('manual', 'approximate_browser', 'system_assigned');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('registered', 'moderator', 'administrator', 'super_administrator');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ----------------------------------------------------------------------------
-- §2. updated_at trigger function (KEA-DBS-002 §10.8, §11)
-- One shared function, one trigger per table that has updated_at.
-- Naming: function public.set_updated_at(), triggers trg_<table>_updated_at.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ============================================================================
-- §3. TABLES — created in dependency order.
-- OD-4 = A (confirmed 2026-11-20) applies to every REFERENCES clause below:
--   ON DELETE RESTRICT is the default (safe: nothing is silently erased).
--   The ONLY CASCADEs are the two auth-identity FKs marked
--   "OD-4 EXCEPTION" (profiles.id and user_roles.user_id -> auth.users.id).
--   Rationale for the exceptions: the profile/role rows are inseparable
--   from the auth identity itself; deleting the auth user is governed by
--   the account-deletion lifecycle (OD-13, TBD), and moderation/audit
--   evidence lives in other tables that stay RESTRICT. Decision A keeps
--   CASCADE on these two (confirmed 2026-11-20); the RESTRICT alternative
--   is recorded in the decision sheet. (With RESTRICT, Supabase could not
--   delete an auth user until the app deletes the profile/role rows first.)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 PROFILES DOMAIN (KEA-DBS-002 §4.1)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  -- OD-4 EXCEPTION (CASCADE): see §3 header. Profile row = auth identity.
  username text NOT NULL,
  display_name text NOT NULL,
  avatar_url text,
  bio text,
  profile_visibility profile_visibility NOT NULL DEFAULT 'public',
  account_status account_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
  -- NO role column (D-18). Roles live only in user_roles (§3.9).
  -- UNDERSPECIFIED: no character limits in the spec (OD-5, TBD) — no
  -- length CHECKs are added here. Username uniqueness is case-insensitive
  -- via the lower(username) index below (§10.2), not a column UNIQUE.
);

CREATE TABLE IF NOT EXISTS public.user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: spec undecided between preference_key/value and
  -- structured columns (§4.1.2). Draft = key-value model; preference_value
  -- is JSONB (draft type choice — the spec gives no type).
  preference_key text NOT NULL,
  preference_value jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_preferences_user_key_unique UNIQUE (user_id, preference_key)
  -- Authoritative permissions must never be stored here (§4.1.2).
);

CREATE TABLE IF NOT EXISTS public.user_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  consent_type text NOT NULL,
  -- UNDERSPECIFIED: document_version format is not specified (TEXT assumed).
  document_version text NOT NULL,
  accepted boolean NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT now(),
  withdrawn_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT user_consents_withdrawn_after_recorded
    CHECK (withdrawn_at IS NULL OR withdrawn_at >= recorded_at)
  -- History is preserved: withdrawing sets withdrawn_at, never deletes (§4.1.3).
);

CREATE TABLE IF NOT EXISTS public.user_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  blocked_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_blocks_no_self_block CHECK (blocker_id <> blocked_id),
  CONSTRAINT user_blocks_pair_unique UNIQUE (blocker_id, blocked_id)
);

-- ----------------------------------------------------------------------------
-- 3.2 LOCATIONS DOMAIN (KEA-DBS-002 §4.8) — before communities (FK target)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  -- UNDERSPECIFIED: location_type values are not listed in the spec (TEXT).
  location_type text NOT NULL,
  parent_location_id uuid REFERENCES public.locations (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: precision/SRID/rounding rule is TBD (OD-8 / DB-OD-007).
  -- geography(Point, 4326) is the storage type only; app logic must
  -- coarsen/round before storing. Never store exact user coordinates here.
  approximate_geography geography(Point, 4326),
  -- UNDERSPECIFIED: locations.status values are not listed (TEXT, no CHECK).
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_location_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  location_id uuid REFERENCES public.locations (id) ON DELETE RESTRICT,
  approximate_geography geography(Point, 4326),
  -- Location source is a closed set (§5), so it uses the enum (OD-3).
  location_source location_source NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
  -- No created_at in the spec's field list (§4.8.2); none is added.
);

-- ----------------------------------------------------------------------------
-- 3.3 COMMUNITIES DOMAIN (KEA-DBS-002 §4.5) — before posts (FK target)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.communities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text NOT NULL,
  description text,
  -- UNDERSPECIFIED: category values are not listed in the spec (TEXT,
  -- nullable — a community without an approved category must not be
  -- forced into an invented one).
  category text,
  location_id uuid REFERENCES public.locations (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: communities.status values are not listed (TEXT, no CHECK).
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.community_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid NOT NULL REFERENCES public.communities (id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  -- No DEFAULT on membership_status: whether joining is open (active) or
  -- needs approval (pending) is an unapproved join policy — the app must
  -- supply the value explicitly. Do not silently default it.
  membership_status community_membership_status NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT community_members_user_community_unique UNIQUE (community_id, user_id)
);

-- ----------------------------------------------------------------------------
-- 3.4 SOCIAL DOMAIN (KEA-DBS-002 §4.2)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  content text NOT NULL,
  -- UNDERSPECIFIED: post visibility values (see post_visibility enum note).
  visibility post_visibility NOT NULL DEFAULT 'public',
  is_anonymous boolean NOT NULL DEFAULT false,
  -- Anonymous changes public attribution only; author_id is always stored
  -- internally for safety/enforcement (§4.2.1, §8.6). Guests cannot post.
  community_id uuid REFERENCES public.communities (id) ON DELETE RESTRICT,
  status post_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
  -- Soft-delete (deleted_at) per §12.3; retention durations TBD (OD-14).
  -- UNDERSPECIFIED: no character limit CHECK (OD-5, TBD).
);

CREATE TABLE IF NOT EXISTS public.post_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.posts (id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  reaction_type reaction_type NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT post_reactions_user_post_unique UNIQUE (post_id, user_id)
  -- One active reaction per user per post (§4.2.2, §6.3).
);

CREATE TABLE IF NOT EXISTS public.comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id uuid NOT NULL REFERENCES public.posts (id) ON DELETE RESTRICT,
  author_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  content text NOT NULL,
  -- Comments use the same lifecycle as posts (published/hidden/removed/
  -- deleted). DRAFT assumption — the spec lists a status field but no
  -- values for comments; confirm before approval.
  status post_status NOT NULL DEFAULT 'published',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
  -- Nested replies are NOT in the MVP (§4.2.3): no parent_comment_id.
  -- UNDERSPECIFIED: no character limit CHECK (OD-5, TBD).
);

-- ----------------------------------------------------------------------------
-- 3.5 POLLS DOMAIN (KEA-DBS-002 §4.3)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  -- OD-1 = A (confirmed 2026-11-20): NULLABLE — a poll may be standalone
  -- or attached to a post. Alternative (NOT NULL: polls always attached
  -- to a post) is recorded in the decision sheet and NOT applied. Either
  -- way the FK itself is ON DELETE RESTRICT: deleting a post must not
  -- erase its poll or votes; the approved retention flow handles those
  -- first (§12.4).
  post_id uuid REFERENCES public.posts (id) ON DELETE RESTRICT,
  creator_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  question text NOT NULL,
  selection_type poll_selection_type NOT NULL,
  status poll_status NOT NULL DEFAULT 'draft',
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT polls_expiry_valid CHECK (expires_at IS NULL OR expires_at > created_at)
  -- UNDERSPECIFIED: poll option limits and expiry defaults (OD-6, TBD).
  -- "At least two valid options before publication" (§4.3.2) is an
  -- application rule, not enforceable by a column CHECK — it is NOT
  -- faked here with a trigger; enforce it in the publish flow.
);

CREATE TABLE IF NOT EXISTS public.poll_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.polls (id) ON DELETE RESTRICT,
  option_text text NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT poll_options_display_order_nonnegative CHECK (display_order >= 0),
  CONSTRAINT poll_options_poll_order_unique UNIQUE (poll_id, display_order)
  -- DRAFT CHOICE: display_order unique per poll (deterministic ordering,
  -- §4.3.2). If two options legitimately share an order value, drop the
  -- UNIQUE and keep only the non-negative CHECK.
  -- Option mutation after votes is TBD (OD-2) — no trigger pretends to
  -- enforce it here.
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.polls (id) ON DELETE RESTRICT,
  option_id uuid NOT NULL REFERENCES public.poll_options (id) ON DELETE RESTRICT,
  -- Registered voters: user_id set, guest_session_id NULL.
  -- Guest voters: user_id NULL, guest_session_id set (D-03/D-11).
  -- EXTENSION X-1 (approved 2026-11-20): guest_session_id is NOT in the
  -- spec's field list (§4.3.3); it is added here because the spec requires
  -- guest votes to be tied to the guest session only, never to an account,
  -- and there is no other column that can carry that.
  user_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  guest_session_id text,
  -- NO DEFAULT on submission_id: one vote operation = one submission_id
  -- shared by all its rows (§4.3.3). A per-row default would silently
  -- break grouping. The application MUST supply it (e.g. gen_random_uuid()
  -- generated once per vote operation in the transaction, §10.9).
  submission_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT poll_votes_exactly_one_voter
    CHECK ((user_id IS NOT NULL)::integer + (guest_session_id IS NOT NULL)::integer = 1),
  CONSTRAINT poll_votes_user_option_unique UNIQUE (poll_id, user_id, option_id),
  CONSTRAINT poll_votes_guest_option_unique UNIQUE (poll_id, guest_session_id, option_id)
  -- The UNIQUEs prevent the same option being selected twice in/across
  -- submissions. "One active submission per user per poll" (D-11) is
  -- enforced by the transaction-safe vote operation (§10.9: replace the
  -- old submission atomically), NOT by a unique index — a unique index
  -- cannot express "one submission, many option rows, replaceable".
  -- A selected option must belong to the same poll: enforce in the vote
  -- transaction (§10.9 step 4); a cross-table CHECK cannot do it.
);

-- ----------------------------------------------------------------------------
-- 3.6 GAMES DOMAIN (KEA-DBS-002 §4.4)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL,
  name text NOT NULL,
  description text,
  -- UNDERSPECIFIED: game_type values are not listed in the spec (TEXT).
  game_type text NOT NULL,
  -- UNDERSPECIFIED: games.status values are not listed (TEXT, no CHECK).
  status text NOT NULL,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
  -- No seed rows in this migration. The 3 approved games are seeded by a
  -- separate Product P1 migration once rules/scoring are approved (OD-9).
);

CREATE TABLE IF NOT EXISTS public.game_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid NOT NULL REFERENCES public.games (id) ON DELETE RESTRICT,
  question_text text NOT NULL,
  -- UNDERSPECIFIED: question_type values and difficulty scale are not
  -- specified (TEXT; difficulty nullable — e.g. This or That has no
  -- difficulty). Both are TBD under OD-9.
  question_type text NOT NULL,
  difficulty text,
  configuration jsonb NOT NULL DEFAULT '{}'::jsonb,
  display_order integer NOT NULL DEFAULT 0,
  -- UNDERSPECIFIED: game_questions.status values are not listed (TEXT).
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT game_questions_display_order_nonnegative CHECK (display_order >= 0),
  CONSTRAINT game_questions_game_order_unique UNIQUE (game_id, display_order)
  -- DRAFT CHOICE: display_order unique per game (see poll_options note).
);

CREATE TABLE IF NOT EXISTS public.game_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.game_questions (id) ON DELETE RESTRICT,
  option_text text NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  -- is_correct is server-only: never include it in untrusted public
  -- responses (§4.4.3). RLS policies (later migration) must enforce that.
  is_correct boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT game_options_display_order_nonnegative CHECK (display_order >= 0),
  CONSTRAINT game_options_question_order_unique UNIQUE (question_id, display_order)
  -- DRAFT CHOICE: display_order unique per question (see poll_options note).
);

CREATE TABLE IF NOT EXISTS public.game_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  game_id uuid NOT NULL REFERENCES public.games (id) ON DELETE RESTRICT,
  -- Registered players: user_id set. Guests: user_id NULL and
  -- guest_session_id set (D-03; same extension X-1 as poll_votes,
  -- approved 2026-11-20).
  user_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  guest_session_id text,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  score integer NOT NULL DEFAULT 0,
  status game_session_status NOT NULL DEFAULT 'active',
  configuration_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT game_sessions_exactly_one_player
    CHECK ((user_id IS NOT NULL)::integer + (guest_session_id IS NOT NULL)::integer = 1),
  CONSTRAINT game_sessions_score_nonnegative CHECK (score >= 0),
  CONSTRAINT game_sessions_completed_needs_timestamp
    CHECK (status <> 'completed' OR completed_at IS NOT NULL),
  CONSTRAINT game_sessions_completed_after_start
    CHECK (completed_at IS NULL OR completed_at >= started_at)
  -- Scores are server-calculated only (§4.4.4); never trust a client
  -- score. No UNIQUE (game_id, user_id): the spec does not decide a
  -- replay policy (OD-9) — replays are allowed by default in this draft.
  -- Guest scores are not saved to a profile and never reach leaderboards.
);

CREATE TABLE IF NOT EXISTS public.game_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES public.game_sessions (id) ON DELETE RESTRICT,
  question_id uuid NOT NULL REFERENCES public.game_questions (id) ON DELETE RESTRICT,
  selected_option_id uuid REFERENCES public.game_options (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: answer_payload shape is not specified (JSONB, nullable).
  answer_payload jsonb,
  is_correct boolean NOT NULL DEFAULT false,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT game_answers_session_question_unique UNIQUE (session_id, question_id)
  -- One answer per session/question (§6.3) — DRAFT default. If a game is
  -- later approved to allow multiple attempts per question (OD-9), this
  -- UNIQUE must be dropped by a follow-up migration.
  -- The question must belong to the session's game and the option to the
  -- question: enforce in trusted server logic (§4.4.5); a CHECK cannot
  -- express cross-table membership.
);

-- ----------------------------------------------------------------------------
-- 3.7 NOTIFICATIONS DOMAIN (KEA-DBS-002 §4.6)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  actor_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: notification_type values (event categories) are TBD
  -- (OD-12). TEXT, no CHECK — do not invent the category list.
  notification_type text NOT NULL,
  -- Polymorphic reference: PostgreSQL cannot FK across multiple target
  -- tables (§4.6.1). entity_type/entity_id are validated in trusted
  -- application logic; no FK is faked here.
  entity_type text,
  entity_id uuid,
  title text NOT NULL,
  body text NOT NULL,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  notification_type text NOT NULL,
  -- DRAFT DEFAULTS: in-app on, push off. Push must never be sent without
  -- a valid subscription and permission (§4.6.2). Confirm the defaults
  -- before approval — the spec does not state them.
  in_app_enabled boolean NOT NULL DEFAULT true,
  push_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT notification_preferences_user_type_unique UNIQUE (user_id, notification_type)
);

-- ----------------------------------------------------------------------------
-- 3.8 SAFETY AND MODERATION DOMAIN (KEA-DBS-002 §4.7)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  -- Polymorphic target (post / comment / poll / user / ...): validated in
  -- trusted application logic; no FK across tables (§4.6.1 pattern).
  -- UNDERSPECIFIED: target_type values are not listed in the spec (TEXT).
  target_type text NOT NULL,
  target_id uuid NOT NULL,
  reason report_reason NOT NULL,
  details text,
  status report_status NOT NULL DEFAULT 'open',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
  -- Guests may not report (D-03): reporter_id is NOT NULL by design.
);

CREATE TABLE IF NOT EXISTS public.moderation_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid REFERENCES public.reports (id) ON DELETE RESTRICT,
  moderator_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  subject_user_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  target_type text,
  target_id uuid,
  -- UNDERSPECIFIED: action_type values must be approved and mapped to
  -- actual enforcement capabilities (§4.7.2) — not listed, so TEXT.
  action_type text NOT NULL,
  reason text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  CONSTRAINT moderation_actions_expiry_valid
    CHECK (expires_at IS NULL OR expires_at >= created_at)
  -- RESTRICT on report_id is deliberate: an action must never silently
  -- erase the report (evidence) it came from (§6.2).
);

CREATE TABLE IF NOT EXISTS public.moderation_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  action_type text NOT NULL,
  target_type text NOT NULL,
  target_id uuid NOT NULL,
  reason text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
  -- Append-only for ordinary application roles (§4.7.3). Append-only is
  -- enforced by RLS policy (later migration: no UPDATE/DELETE for
  -- non-privileged roles), NOT by a trigger here — a trigger-based
  -- immutability rule would also block legitimate privileged correction
  -- and is not in the spec.
);

-- ----------------------------------------------------------------------------
-- 3.9 ADMINISTRATION DOMAIN (KEA-DBS-002 §4.9)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE RESTRICT,
  action_type text NOT NULL,
  target_type text NOT NULL,
  target_id uuid NOT NULL,
  before_state jsonb,
  after_state jsonb,
  request_id text,
  created_at timestamptz NOT NULL DEFAULT now()
  -- Sensitive values must be redacted before writing (§4.9.1) — that is
  -- an application rule; the database cannot know what is sensitive.
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  -- OD-4 EXCEPTION (CASCADE): see §3 header. A role assignment is not
  -- evidence; the grant/revoke itself is recorded in admin_audit_logs.
  role user_role NOT NULL,
  -- granted_by is NULLABLE only for the initial bootstrap grant: the very
  -- first super_administrator has no existing profile to grant it. Every
  -- later grant must set granted_by (enforce in the privileged server
  -- flow, D-18). Do not use NULL granted_by for routine grants.
  granted_by uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  granted_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  CONSTRAINT user_roles_revoked_after_granted
    CHECK (revoked_at IS NULL OR revoked_at >= granted_at)
  -- One ACTIVE role row per user is enforced by the unique partial index
  -- below (§4.9.2), not by a table constraint. A revoked row is history.
);
-- NOTE: profiles has NO role column (D-18). Role resolution is server-side
-- from user_roles only; never from client claims; no self-assignment.

-- ----------------------------------------------------------------------------
-- 3.10 ANALYTICS DOMAIN (KEA-DBS-002 §4.10)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles (id) ON DELETE RESTRICT,
  -- UNDERSPECIFIED: event_name values — the spec lists examples only
  -- (post_created, poll_voted, ...) and no allow-list (OD-12). TEXT.
  -- Guest events use session_reference; user_id stays NULL for guests.
  event_name text NOT NULL,
  event_version integer NOT NULL DEFAULT 1,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  session_reference text,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT analytics_events_version_positive CHECK (event_version >= 1)
  -- Analytics is never authoritative transactional data (§4.10).
  -- Retention / aggregation / deletion behaviour TBD (OD-14 / DB-OD-010).
);

-- ============================================================================
-- §4. INDEXES (KEA-DBS-002 §7)
-- Table-level UNIQUE constraints above already create indexes for:
--   post_reactions (post_id, user_id) · community_members (community_id,
--   user_id) · notification_preferences (user_id, notification_type) ·
--   poll_options / game_questions / game_options (parent, display_order) ·
--   game_answers (session_id, question_id) · user_blocks (blocker, blocked) ·
--   user_preferences (user_id, preference_key) · poll_votes (both uniques).
-- Those §7 rows are NOT re-indexed here — no redundant indexes (§7).
-- "Draft addition" = an access pattern the app plainly needs but §7 does
-- not list; confirm or drop before approval.
-- ============================================================================

-- §10.2 case-insensitive username uniqueness.
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_uidx
  ON public.profiles (lower(username));

-- One active role row per user (D-18 / §4.9.2): partial unique index.
CREATE UNIQUE INDEX IF NOT EXISTS user_roles_user_active_uidx
  ON public.user_roles (user_id) WHERE revoked_at IS NULL;

-- Profiles: account-status filtering (§7).
CREATE INDEX IF NOT EXISTS profiles_account_status_idx
  ON public.profiles (account_status);

-- Posts: author/time retrieval, published-feed pagination, community feed (§7).
CREATE INDEX IF NOT EXISTS posts_author_created_idx
  ON public.posts (author_id, created_at DESC);
CREATE INDEX IF NOT EXISTS posts_feed_idx
  ON public.posts (status, created_at DESC) WHERE status = 'published';
CREATE INDEX IF NOT EXISTS posts_community_idx
  ON public.posts (community_id, created_at DESC) WHERE community_id IS NOT NULL;

-- Comments: post/time retrieval (§7).
CREATE INDEX IF NOT EXISTS comments_post_created_idx
  ON public.comments (post_id, created_at);

-- Polls: active retrieval + expiration processing (§7).
CREATE INDEX IF NOT EXISTS polls_active_idx
  ON public.polls (status, expires_at) WHERE status = 'active';

-- Poll votes: submission lookup + result aggregation (§7).
CREATE INDEX IF NOT EXISTS poll_votes_poll_user_idx
  ON public.poll_votes (poll_id, user_id);
CREATE INDEX IF NOT EXISTS poll_votes_poll_option_idx
  ON public.poll_votes (poll_id, option_id);

-- Game sessions: user session history (§7).
CREATE INDEX IF NOT EXISTS game_sessions_user_idx
  ON public.game_sessions (user_id, created_at DESC);

-- Notifications: recipient/time retrieval + unread lookup (§7).
CREATE INDEX IF NOT EXISTS notifications_recipient_created_idx
  ON public.notifications (recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_unread_idx
  ON public.notifications (recipient_id, created_at DESC) WHERE read_at IS NULL;

-- Reports: status/time review queues (§7).
CREATE INDEX IF NOT EXISTS reports_status_created_idx
  ON public.reports (status, created_at DESC);

-- Moderation actions: subject + moderator history (§7).
CREATE INDEX IF NOT EXISTS moderation_actions_subject_idx
  ON public.moderation_actions (subject_user_id, created_at DESC)
  WHERE subject_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS moderation_actions_moderator_idx
  ON public.moderation_actions (moderator_id, created_at DESC);

-- Locations: geospatial search (§7) — GIST on the PostGIS column.
CREATE INDEX IF NOT EXISTS locations_geography_idx
  ON public.locations USING gist (approximate_geography);

-- User location preferences: user lookup (§7).
CREATE INDEX IF NOT EXISTS user_location_preferences_user_idx
  ON public.user_location_preferences (user_id);

-- Admin audit logs: actor/time lookup (§7).
CREATE INDEX IF NOT EXISTS admin_audit_logs_actor_created_idx
  ON public.admin_audit_logs (actor_id, created_at DESC);

-- Analytics events: event/time analysis (§7).
CREATE INDEX IF NOT EXISTS analytics_events_name_time_idx
  ON public.analytics_events (event_name, occurred_at DESC);

-- Draft additions (not in §7 — confirm or drop before approval):
CREATE INDEX IF NOT EXISTS locations_parent_idx
  ON public.locations (parent_location_id);  -- location hierarchy lookup
CREATE INDEX IF NOT EXISTS user_consents_user_idx
  ON public.user_consents (user_id, recorded_at DESC);  -- consent history lookup
CREATE INDEX IF NOT EXISTS user_blocks_blocker_idx
  ON public.user_blocks (blocker_id, created_at DESC);  -- "who did I block" lookup
CREATE INDEX IF NOT EXISTS reports_reporter_idx
  ON public.reports (reporter_id, created_at DESC);  -- "my reports" lookup
CREATE INDEX IF NOT EXISTS moderation_audit_logs_actor_idx
  ON public.moderation_audit_logs (actor_id, created_at DESC);  -- audit history lookup

-- ============================================================================
-- §5. updated_at TRIGGERS (KEA-DBS-002 §10.8)
-- One shared function (public.set_updated_at, §2), one trigger per table
-- that has an updated_at column: 14 tables. Tables WITHOUT updated_at in
-- the spec get NO trigger: poll_options, poll_votes, game_options,
-- game_sessions, game_answers, notifications, moderation_actions,
-- moderation_audit_logs, admin_audit_logs, analytics_events, user_roles.
-- user_location_preferences HAS updated_at (§4.8.2) and IS in the list.
-- ============================================================================
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'profiles', 'user_preferences', 'posts', 'post_reactions', 'comments',
    'polls', 'games', 'game_questions', 'communities', 'community_members',
    'notification_preferences', 'reports', 'locations',
    'user_location_preferences'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_updated_at ON public.%I; '
      'CREATE TRIGGER trg_%s_updated_at '
      'BEFORE UPDATE ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t, t, t, t);
  END LOOP;
END $$;

-- ============================================================================
-- §6. ROW LEVEL SECURITY — ENABLE ONLY (KEA-DBS-002 §8.1, §10.6)
-- RLS is enabled on every app table (27/27). NO policies are created here:
-- policies are a separate, later migration built from the §8.3 matrix and
-- tested per role (§15.2). RLS enabled with no policies denies all access
-- to anon/authenticated by default — that is the safe starting state.
-- ============================================================================
DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'profiles', 'user_preferences', 'user_consents', 'user_blocks',
    'posts', 'post_reactions', 'comments',
    'polls', 'poll_options', 'poll_votes',
    'games', 'game_questions', 'game_options', 'game_sessions', 'game_answers',
    'communities', 'community_members',
    'notifications', 'notification_preferences',
    'reports', 'moderation_actions', 'moderation_audit_logs',
    'locations', 'user_location_preferences',
    'admin_audit_logs', 'user_roles',
    'analytics_events'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);
  END LOOP;
END $$;

COMMIT;

-- ============================================================================
-- POST-APPLY VERIFICATION CHECKLIST (run manually after applying; §15.1)
--   NOTE: PostGIS creates its own spatial_ref_sys table in public, so
--   public-schema totals include it. App tables are 27; totals below are
--   stated both ways. (Corrected 2026-11-20 after the first PGlite run:
--   the draft's "expect 36 indexes" forgot primary-key indexes.)
--   SELECT count(*) FROM pg_tables WHERE schemaname='public'
--     AND tablename <> 'spatial_ref_sys';                       -- expect 27
--   SELECT count(*) FROM pg_type WHERE typtype='e'
--     AND typnamespace='public'::regnamespace;                 -- expect 13
--   SELECT count(*) FROM pg_indexes
--     WHERE schemaname='public';                               -- expect 64
--     -- 64 = 25 CREATE INDEX statements in §4 (incl. 2 UNIQUE ones)
--     --    + 11 indexes created automatically by table-level UNIQUE
--     --    constraints + 27 primary-key indexes + 1 spatial_ref_sys
--     --    primary-key index. Verify the full list; do not trust this comment.
--   SELECT count(*) FROM information_schema.triggers
--     WHERE trigger_schema='public';                           -- expect 14
--   SELECT count(*) FROM information_schema.table_constraints
--     WHERE constraint_type='FOREIGN KEY'
--     AND table_schema='public';                               -- expect 42
--     -- 42 = 40 ON DELETE RESTRICT + 2 ON DELETE CASCADE (the two
--     -- auth-identity FKs: profiles.id, user_roles.user_id).
--   SELECT tablename FROM pg_tables
--     WHERE schemaname='public' AND tablename <> 'spatial_ref_sys'
--     AND rowsecurity = false;                                 -- expect 0 rows
--     -- (spatial_ref_sys alone has RLS off; it is a PostGIS system
--     -- table and is expected to be the one row if unfiltered.)
--   Confirm: no policies exist yet (policies migration still to come):
--   SELECT count(*) FROM pg_policies WHERE schemaname='public'; -- expect 0
-- Then: RLS policy tests per role (§15.2), poll integrity tests (§15.4),
-- and a seeded-staging apply test (§9.2 step 7) before any approval.
-- ============================================================================
