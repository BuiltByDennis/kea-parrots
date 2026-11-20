// Kea Parrot — Sentry browser init (Product P0 scaffold).
// DSN from SENTRY_DSN only. No PII, tokens, passwords, or service-role
// keys in events. Traces are off until an approved sampling rate exists.

import * as Sentry from "@sentry/nextjs";

const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN ?? process.env.SENTRY_DSN;

if (dsn) {
  Sentry.init({
    dsn,
    tracesSampleRate: 0,
    sendDefaultPii: false,
  });
}
