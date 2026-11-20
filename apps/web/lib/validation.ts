// Kea Parrot — validation entry point (Product P0 scaffold).
// Zod v4 (pinned 4.6.7) is the only validation library. Server-side
// validation only — client validation is UX only (KEA-API-004 §9).
// Shared schemas land in P1 (packages/validation).

export * from "zod";
