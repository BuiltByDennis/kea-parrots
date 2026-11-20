// Kea Parrot — cursor-pagination helpers (Product P0 scaffold).
// Opaque cursors only (KEA-API-004 §10.2). Page-size defaults/max are TBD
// (OD-10) — callers must pass an explicit, allow-listed limit until then.

export function encodeCursor(payload: Record<string, unknown>): string {
  return Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
}

export function decodeCursor(cursor: string): Record<string, unknown> | null {
  try {
    const parsed: unknown = JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"));
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
    return null;
  } catch {
    return null;
  }
}
