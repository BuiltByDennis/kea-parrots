// Kea Parrot — Playwright config (Product P0)
// Pinned: @playwright/test 1.65.1. E2E tests live at the repo root
// (tests/e2e/); journeys A–F land in P1 (KEA-PRD-001 §27).

import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "../../tests/e2e",
  timeout: 30 * 1000,
  retries: 0,
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:3000",
    trace: "on-first-retry",
  },
});
