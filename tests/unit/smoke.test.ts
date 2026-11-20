// Kea Parrot — smoke test (Product P0 scaffold only).
// Proves the Vitest runner works. Real unit tests land in Product P1.

import { describe, expect, it } from "vitest";

describe("smoke", () => {
  it("runs", () => {
    expect(true).toBe(true);
  });
});
