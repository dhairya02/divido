# Divido Web — architecture

The Next.js app's main modules and data flow. For setup steps and scripts
see [`README.md`](README.md); for endpoint-by-endpoint request/response
shapes see [`../docs/public-api-reference.md`](../docs/public-api-reference.md).

## Overview

- Next.js 15 App Router for pages and API route handlers
- Prisma ORM against SQLite (dev); the same schema is intended to work
  against Postgres in production
- NextAuth (credentials provider, bcrypt hashes) for sessions
- Zod for request-body validation in every route handler
- Tailwind CSS v4 for styles, shared brand tokens defined in
  [`packages/ui-assets/README.md`](../packages/ui-assets/README.md)

## Data model (Prisma)

- `Contact`: people you can add to a bill
- `Bill`: header info (title, subtotal, tax/tip rates, currency, taxMode)
- `BillParticipant`: links a `Contact` to a `Bill`
- `Item`: line items with price, quantity, `taxable`, optional `taxRatePct`
- `ItemShare`: per-item weights per participant

See `prisma/schema.prisma` for details.

## Server endpoints (App Route Handlers)

- `GET/POST /api/contacts`
- `GET/POST /api/bills` and `GET/DELETE /api/bills/:id`
- `POST/PUT/PATCH/DELETE /api/bills/:id/items`
- `POST /api/bills/:id/participants`
- `GET /api/bills/:id/calc` → calls the pure calculator in `lib/calc.ts`

## Calculator (lib/calc.ts)

- Computes pre-tax allocations by item using weights and round-half-up
- Adjusts rounding drift deterministically by fractional parts
- Computes tax/tip either globally or at item-level, distributing deterministically
- Verifies penny-accurate totals: sum of owed equals subtotal + tax + tip

This is the canonical implementation. The Flutter mobile app re-implements
it verbatim in `mobile/lib/utils/calc.dart` and verifies parity in
`mobile/test/calc_test.dart`. Any change here must land alongside the same
change in the Dart port, with the parity test still green.

## UI

- `app/` pages for dashboard, contacts, bills list, new bill, bill detail
- Components:
  - `ItemShareEditor`: edit per-participant weights per item
  - `Money`: currency formatting
  - `ReceiptOCR`: client-side OCR for receipts (HEIC supported)
  - `Modal`, `ConfirmDialog`, `AlertDialog`: reusable dialog primitives
  - `HistoryNav`: header back/forward (fork/spoon icons)

## Styling & Theming

- Tailwind utilities + custom classes in `app/globals.css`
- Brand variables defined via CSS custom properties
- Garamond font via `next/font`

## Error handling

- Zod validates incoming request bodies; handlers return 400 on invalid input
- Calculate route returns explicit errors for missing shares or subtotal mismatch, with formatted currency shown in UI
