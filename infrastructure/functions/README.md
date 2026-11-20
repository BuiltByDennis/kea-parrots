# Kea Parrot — functions (Product P0)

Directory only in P0. Supabase Edge / database functions land in Product
P1, only for approved uses (KEA-DBS-002 §11): updated_at timestamps,
atomic voting, specific audit events, approved DB-side operations. Any
`SECURITY DEFINER` function needs additional review; never use privileged
functions as an RLS shortcut.
