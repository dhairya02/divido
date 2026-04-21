# Shared contracts

This folder is **reference-only** — it documents the data model and HTTP API
surface the two apps in this monorepo agree on. It does not contain code.

- The web app ([`web/`](../../web/)) implements the API and persists to
  SQLite via Prisma.
- The mobile app ([`mobile/`](../../mobile/)) is fully offline; it uses the
  same model shapes locally so the calculator and UI stay aligned, but it
  does not call the HTTP API.

## Authoritative sources

| What                          | Where                                                     |
|-------------------------------|-----------------------------------------------------------|
| HTTP API (every endpoint)     | [`docs/public-api-reference.md`](../../docs/public-api-reference.md) |
| Database schema               | [`web/prisma/schema.prisma`](../../web/prisma/schema.prisma)         |
| Split-calculation algorithm   | [`web/lib/calc.ts`](../../web/lib/calc.ts) (mirrored in [`mobile/lib/utils/calc.dart`](../../mobile/lib/utils/calc.dart)) |
| Request/response validation   | [`web/lib/schemas.ts`](../../web/lib/schemas.ts) (Zod)               |

The summaries below are convenience overviews; treat the files above as
ground truth and update those, not this README.

## Core models

| Model              | Purpose                                                  | Key fields                                                              |
|--------------------|----------------------------------------------------------|-------------------------------------------------------------------------|
| `User`             | Web-only; authenticates a browser session                | `id`, `email`, `name`, `passwordHash`                                  |
| `Contact`          | A person who can appear on a bill                        | `name`, `email?`, `phone?`, `venmo?`, `cashapp?`                        |
| `Bill`             | The header for a single bill                             | `title`, `venue`, `subtotalCents`, `taxRatePct`, `tipRatePct`, `convenienceFeeRatePct`, `taxMode` |
| `Item`             | A line item on a bill                                    | `name`, `priceCents`, `quantity`, `taxable`, `taxRatePct?`              |
| `BillParticipant`  | Join row: a `Contact` is on a `Bill`                     | `billId`, `contactId`                                                   |
| `ItemShare`        | Per-participant weight for a single item                 | `itemId`, `billParticipantId`, `weight`                                 |

The mobile app keeps the same shapes minus `User` and the NextAuth session
tables (single-user device, no auth needed). See
[`mobile/README.md#data-model-sqlite-on-device`](../../mobile/README.md#data-model-sqlite-on-device).

## API endpoint groups

For request/response bodies, status codes, and examples, see
[`docs/public-api-reference.md`](../../docs/public-api-reference.md). At a
glance:

- **Auth & account** — `POST /api/register`, NextAuth handler, `DELETE /api/me`
- **Profile** — `GET /api/me`, `GET /api/me/contact`, `GET /api/me/stats`,
  `PATCH /api/me/profile`, `PATCH /api/me/contact`, `POST /api/me/password`
- **Contacts** — CRUD under `/api/contacts` and `/api/contacts/[id]`
- **Bills** — `GET/POST /api/bills`, `GET/PATCH/DELETE /api/bills/[id]`,
  `GET /api/bills/[id]/calc`
- **Bill items** — `POST/PUT/PATCH/DELETE /api/bills/[id]/items`
- **Bill participants** — `POST /api/bills/[id]/participants`

Balances are computed client-side from bills + participants; no dedicated
endpoint.

## Algorithm parity

`calculateSplit` in `web/lib/calc.ts` is the canonical implementation. The
Dart port in `mobile/lib/utils/calc.dart` is verified to penny-match by
`mobile/test/calc_test.dart`. Any change to either file must land in **both**
in the same change, with the parity test still green.
