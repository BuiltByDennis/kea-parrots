# Kea Parrot — worker (Product P0 placeholder)

No worker exists in P0 (KEA-SAD-001 ADR-010: a dedicated worker only when
justified). Approved async operations — poll expiration, notification
processing, scheduled maintenance, analytics aggregation, data cleanup —
do not exist yet, so there is nothing to run. A worker implementation is a
Product P1 decision, only if an approved workload cannot be handled by the
app or platform.
