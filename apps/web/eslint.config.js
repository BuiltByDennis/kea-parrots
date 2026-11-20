// Kea Parrot — ESLint flat config (Product P0)
// ESLint 10 is flat-config only: there is no .eslintrc.json in this repo.
// Pinned: eslint 10.15.0, eslint-config-next 16.4.6 (see docs/ADR/001).
// `next lint` was removed in Next.js 16 — lint via `npm run lint` (eslint CLI).

import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  globalIgnores([".next/**", "out/**", "build/**", "node_modules/**", "next-env.d.ts"]),
]);

export default eslintConfig;
