// Kea Parrot — Supabase browser client factory (Product P0 scaffold).
// Browser client uses the anon key ONLY — never the service-role key
// (KEA-SAD-001 §9.3). NOTE (W6): use the new publishable API key, not the
// legacy anon JWT key (deprecated end of 2026).

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

export function createBrowserSupabaseClient(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error(
      "Supabase is not configured: set NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY.",
    );
  }
  return createBrowserClient(url, anonKey);
}
