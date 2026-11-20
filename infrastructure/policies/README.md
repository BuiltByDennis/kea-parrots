# Kea Parrot — policies (Product P0)

Directory only in P0. Row Level Security policy SQL lands in Product P1
with migration 001 (KEA-DBS-002 §8). RLS is mandatory on every exposed
table; never disable it to fix a query. Policies are tested against all
personas (guest, User A, User B, moderator, administrator, super
administrator) before they ship.
