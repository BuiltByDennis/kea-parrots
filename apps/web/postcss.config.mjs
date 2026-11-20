// Kea Parrot — postcss.config.mjs (Product P0)
// Tailwind v4 is CSS-first: the ONLY PostCSS plugin is @tailwindcss/postcss
// (pinned 4.3.5). There is no `tailwindcss` plugin entry and no autoprefixer
// entry in v4 — the v3-style config (tailwindcss + autoprefixer) was removed
// during the P0 build. See docs/ADR/001 (W4).
// ESM (.mjs) because apps/web/package.json sets "type": "module".

const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
