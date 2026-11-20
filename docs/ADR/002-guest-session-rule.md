# ADR-002 — Guest Session Rule (D-03)

- **Status:** Accepted 2026-11-20 (owner decision).
- **Context:** The Master PRD said guests cannot vote or play; the
  foundation strategy said guests should be able to participate without
  registration. The owner decided: guests can vote/play, with limited time.
- **Decision (canonical Guest Session Rule):** a guest is an unauthenticated
  visitor identified by a server-issued guest-session token — not an
  account. A guest may browse public discovery, vote in polls, and play
  the 3 games, for **60 minutes from the guest session's first vote or
  game start**, ending on browser close, whichever is first. A guest may
  NOT post, comment, react, join communities, or report. One vote per poll
  per guest session; guest votes are counted; guest game scores are not
  saved to a profile and do not appear on leaderboards; nothing transfers
  to a new account on registration. Rate limits apply per guest session
  - IP (thresholds TBD, OD-10).
- **Consequences:**
  - The database must represent guest participation: migration 001 adds
    `guest_session_id` to `poll_votes` and `game_sessions` (the DB spec
    lists no guest identifier; without this column D-03 has no database
    representation). Guest-session token transport/storage is TBD (OD-23).
  - Guest votes are final (see ADR-003): guests may not change or remove
    a vote.
