// Kea Parrot — next.config.ts (Product P0)
// Pinned: next 16.4.6, react 19.3.1, typescript 6.0.3 (see docs/ADR/001).
// App Router is the default in Next.js 16; no `appDir` flag.
//
// Notes:
// - reactStrictMode is ON (catches unsafe behaviour early; required by the
//   P0 security baseline).
// - poweredByHeader is OFF (do not advertise the framework version).
// - No `images.remotePatterns`: the MVP is text-only (KEA-PRD-001 §9.1 —
//   image/audio uploads are NOT in the MVP). Add remote patterns in P1
//   only if an approved upload use case exists (OD-11).
// - No PWA / service-worker config here: PWA installation is a Product P3
//   deliverable (KEA-PRD-001 §29). Do not add offline support in P0/P1
//   (KEA-UX-003 §14 forbids offline publishing/background sync unless
//   separately approved).
// - No redirects/rewrites: routes are defined by the app/ tree.

import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
};

export default nextConfig;
