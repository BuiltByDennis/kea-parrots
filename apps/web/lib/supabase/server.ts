// Kea Parrot — Supabase server client factory (Product P0 scaffold).
// Auth-aware server client. The service-role client is a SEPARATE P1
// module: it must only ever be constructed in trusted server contexts and
// must never be imported by client code (KEA-SAD-001 §9.3).
// Session transport / cookie strategy is TBD (OD-24) — verify against the
// pinned @supabase/ssr 0.12.7 + Next.js 16.4.6 before auth work in P1.

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { SupabaseClient } from "@supabase/supabase-js";

export async function createServerSupabaseClient(): Promise<SupabaseClient> {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      "Supabase is not configured: set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.",
    );
  }
  const cookieStore = await cookies();
  return createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) => cookieStore.set(name, value, options));
        } catch {
          // Called from a Server Component: setting cookies is not allowed
          // there. Middleware/route-handler refresh handles the session.
        }
      },
    },
  });
}
