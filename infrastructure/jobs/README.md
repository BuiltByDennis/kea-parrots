# Kea Parrot — jobs (Product P0)

Directory only in P0. Background-job definitions land in Product P1.
Every job must define its ID, purpose, trigger, input, output,
permissions, retry policy, failure behaviour, logging, and idempotency
(KEA-SAD-001 §11). Jobs must be retry-safe and idempotent, with bounded
execution and no duplicate processing.
