// Kea Parrot — Sentry server init (Product P0 scaffold).
// DSN from SENTRY_DSN only. No PII, tokens, passwords, or service-role
// keys in events. Traces are off until an approved sampling rate exists.

import * as Sentry from "@sentry/nextjs";

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 0,
    sendDefaultPii: false,
  });
}
