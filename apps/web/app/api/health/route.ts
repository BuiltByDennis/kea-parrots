// Kea Parrot — health-check route (Product P0 scaffold only).
// Returns { ok: true }. No auth, no database access, no business logic.

export async function GET() {
  return Response.json({ ok: true });
}
