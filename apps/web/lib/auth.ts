// Kea Parrot — session helpers (Product P0 scaffold).
// Session transport / cookie strategy is TBD (OD-24). No auth logic exists
// in P0; these helpers throw until OD-24 is closed and P1 auth lands.

export function getSessionUser(): never {
  throw new Error("Auth session transport is TBD (OD-24) — no session helpers in P0.");
}
