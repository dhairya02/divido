# UI assets & design tokens

Single source of truth for colors, typography, and spacing shared between the
[web app](../../web/) and the [Flutter mobile app](../../mobile/).

This folder is **reference-only** — the actual values live in:

| Token surface     | Where it's wired up                                                                      |
|-------------------|------------------------------------------------------------------------------------------|
| Web CSS variables | [`web/app/globals.css`](../../web/app/globals.css) and [`web/tailwind.config.ts`](../../web/tailwind.config.ts) |
| Mobile theme      | [`mobile/lib/theme/brand.dart`](../../mobile/lib/theme/brand.dart) (`BrandColors`, `buildBrandTheme`) |
| Logo asset        | [`mobile/assets/images/divido-logo.png`](../../mobile/assets/images/divido-logo.png) (sourced from this folder) |

If a token changes, update both the web and mobile sources in the same PR
and refresh the table below.

## Color palette

| Role             | Hex                              | Notes                                  |
|------------------|----------------------------------|----------------------------------------|
| `primary`        | `#6F8BFF`                        | Header bar, AppBar, focus ring         |
| `secondary`      | `#C77DFF`                        | Primary action buttons, FAB            |
| `accent`         | `#E6FDA3`                        | "Divido" wordmark on the brand header  |
| `muted`          | `#B794D9`                        | Soft accents                           |
| Background       | `#FFFFFF` light / `#111827` dark | App background                         |
| Text             | `#111827` light / `#FFFFFF` dark | Body text                              |
| Border           | `rgba(0,0,0,0.1)` / `rgba(255,255,255,0.1)` | Default border on inputs / cards |

### Semantic colors

| Role     | Hex       |
|----------|-----------|
| Success  | `#065F46` |
| Error    | `#DC2626` |
| Warning  | `#F59E0B` |
| Info     | `#3B82F6` |

## Typography

**Family**: EB Garamond (serif). Loaded via `next/font` on the web, and via
`google_fonts` on mobile.

| Use     | Weight |
|---------|--------|
| Display | 700    |
| Heading | 600    |
| Body    | 400    |

Recommended sizes: `xs 12 / sm 14 / base 16 / lg 18 / xl 20 / 2xl 24` (px).

## Spacing scale

`1 = 0.25rem (4px)`, `2 = 0.5rem (8px)`, `3 = 0.75rem (12px)`,
`4 = 1rem (16px)`, `6 = 1.5rem (24px)`, `8 = 2rem (32px)`. Both apps follow
this scale; deviating requires a token update here.

## Component conventions

- **Buttons**: corner radius `0.375rem`, padding `0.5rem 1rem`. Primary uses
  the `primary` color; secondary uses a `1px` border in the default border
  color.
- **Inputs**: same corner radius and padding; focus ring is `2px` of
  `primary`.
- **Cards**: corner radius `0.5rem`, default border, subtle shadow.

## Logo

`divido-logo.png` — transparent background, square aspect ratio. Used for the
header brand mark on web and the splash / launcher icons on mobile (the
mobile app re-generates platform icons via `flutter_launcher_icons`, see
[`mobile/pubspec.yaml`](../../mobile/pubspec.yaml)).
