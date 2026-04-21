# Divido — Web

A Next.js 15 + Prisma multi-user web app for splitting restaurant bills.
Auth, contacts, bills, items, per-item shares, and a deterministic split
calculator. Receipt OCR via Tesseract.js (HEIC supported).

> Looking for the offline single-user mobile app? See
> [`../mobile/README.md`](../mobile/README.md).

## Status

| Concern         | State                                              |
|-----------------|----------------------------------------------------|
| Build           | ✅ `pnpm build` passes                              |
| Dev server      | ✅ `pnpm dev` (Turbopack) on `http://localhost:3000` |
| Lint            | ✅ `pnpm lint`                                      |
| Database        | SQLite via Prisma; schema in `prisma/schema.prisma` |
| Auth            | NextAuth credentials (bcrypt password hashes)      |
| Public API      | Documented in [`../docs/public-api-reference.md`](../docs/public-api-reference.md) |

## Prerequisites

- Node.js 20+ (tested on 25)
- pnpm 10+

## First-time setup

```bash
cd web
pnpm install
pnpm prisma generate            # generates the Prisma client
pnpm prisma migrate dev         # creates prisma/dev.db
pnpm prisma db seed             # optional sample data
```

The default `.env` already points `DATABASE_URL` at `file:./prisma/dev.db`,
so no extra config is needed for local development.

## Run

```bash
pnpm dev          # http://localhost:3000 with Turbopack
pnpm dev:open     # same, then auto-opens the browser
```

Both apps can be launched together from the repo root with
`./scripts/dev.sh --web` (boots Next.js, then `flutter run`).

## Available scripts

| Command                     | What it does                                              |
|-----------------------------|-----------------------------------------------------------|
| `pnpm dev`                  | Start the dev server (Turbopack)                          |
| `pnpm dev:open`             | Same, then open `http://localhost:3000` in the browser    |
| `pnpm build`                | Production build                                          |
| `pnpm start`                | Run the production build                                  |
| `pnpm lint`                 | ESLint                                                    |
| `pnpm prisma:generate`      | Regenerate the Prisma client                              |
| `pnpm prisma:migrate`       | Create / apply a migration                                |
| `pnpm seed`                 | Re-seed the local database                                |
| `pnpm exec tsx scripts/reset-password.ts <email> <newPassword>` | Reset a user password locally |

## Project layout

```
web/
├── app/                   # App-Router pages and /api route handlers
│   ├── api/               # REST endpoints (see docs/public-api-reference.md)
│   ├── bills/, contacts/, …  # Feature pages
│   └── globals.css        # Brand tokens + utility classes
├── components/            # React components (Money, ItemShare*, ReceiptOCR…)
├── lib/
│   ├── calc.ts            # Bill-split algorithm (round-half-up, deterministic)
│   ├── schemas.ts         # Zod request validators
│   └── db.ts              # Prisma client singleton
├── prisma/
│   ├── schema.prisma      # Source of truth for the data model
│   ├── migrations/
│   └── seed.ts
└── scripts/
    └── reset-password.ts  # Local-dev password reset
```

## Common issues

| Symptom                                            | Fix                                                         |
|----------------------------------------------------|-------------------------------------------------------------|
| `Cannot find module '@prisma/client'`              | `pnpm prisma generate`                                      |
| `Environment variable not found: DATABASE_URL`     | Ensure `web/.env` exists with `DATABASE_URL="file:./prisma/dev.db"` |
| Stale build / weird Turbopack errors               | `rm -rf .next && pnpm dev`                                  |
| Migrations / database connection errors            | `pnpm prisma migrate dev` (creates / refreshes `prisma/dev.db`) |
| Forgot a local password                            | `pnpm exec tsx scripts/reset-password.ts you@example.com NewPass1` |

Passwords are stored as bcrypt hashes; you can't recover an old one — only
overwrite it with the script above.

## Deeper docs

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — modules, data flow, the calculator
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — conventions for code, commits, PRs
- [`../docs/public-api-reference.md`](../docs/public-api-reference.md) — every
  HTTP endpoint, with request/response shapes
