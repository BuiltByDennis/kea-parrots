# Kea Parrot — Design-system starter (Product P0)

## What this starter contains

- `tokens.css` — the 15 token _names_ from KEA-UX-003 §5.1 (brand
  primary/secondary, accent, background, surface, elevated surface,
  primary/secondary/muted text, borders, success, warning, error,
  information, disabled) as an empty Tailwind v4 `@theme` block.
  **Every value is `TBD — OD-18`.** No hex value, no font family, no size,
  no radius and no elevation value exists in P0.
- `app/layout.tsx` — font slot left TBD; no font is loaded in P0.
- Tailwind v4 is CSS-first: there is **no `tailwind.config.ts`** in this
  repo. Tokens are declared in `tokens.css` (`@theme`) and consumed by
  Tailwind utilities; `app/globals.css` imports Tailwind and this file.

## What it does NOT contain (and why)

- No logo, no illustrations, no dark-mode implementation — light/dark
  mode is itself part of OD-18.
- No animation/transition language (OD-18).
- No `components/ui/` primitives (shadcn/ui) — those are added in P1
  once tokens are approved, so components are built on real values
  instead of placeholders.
- No component library, no theme switcher, no branded preview page.

## What unblocks it

**OD-18** (owner: Dennis, needed before Product P1 UI work): brand
colours, typography family/scale, light/dark/both, animation language.
Once OD-18 closes, P1 wires the approved values into `tokens.css`
and adds the first `components/ui/` primitives.
Until then, any UI built in P0 (the smoke-test landing stub) uses
unstyled semantic HTML only.
