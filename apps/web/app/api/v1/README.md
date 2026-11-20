# Kea Parrot — API routes (Product P0)

No API routes exist yet. In Product P1, routes under `app/api/v1/` mirror
KEA-API-004 §12 (65 endpoints) and are thin handlers over the `modules/*`
domain services (KEA-SAD-001 §4): validate with Zod, authenticate via the
verified session, enforce authorisation server-side, then call the domain
service. Routes never contain business rules and never touch the database
directly with privileged credentials.
