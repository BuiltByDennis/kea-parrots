// Kea Parrot — env-var accessor (Product P0 scaffold).
// Fails fast on missing required vars. Never logs secret values.
// Public vars are NEXT_PUBLIC_*; the service-role key must never be read
// from browser code (KEA-SAD-001 §9.3).

export function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error("Missing required environment variable: " + name);
  }
  return value;
}

export function optionalEnv(name: string): string | undefined {
  return process.env[name];
}
