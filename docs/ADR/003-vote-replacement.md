# ADR-003 — Vote replacement (D-11)

- **Status:** Accepted 2026-11-20.
- **Context:** The DB spec required one active submission per poll AND
  permitted vote edits — an unresolved rule flagged in the audit.
- **Decision:** registered users MAY change their vote while a poll is
  open: one active submission per user per poll; changing replaces the
  previous submission atomically; no change after close/expiry. Guests
  may NOT change or remove a vote: one final submission per guest session
  per poll (see ADR-002). Poll results are always computed from stored
  votes, never from client state.
- **Consequences:** vote writes must be transaction-safe (no partial
  votes, no duplicate/concurrent bypass, no votes after expiry); realtime
  reflects committed votes only.
