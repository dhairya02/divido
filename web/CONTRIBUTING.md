# Contributing to Divido (Web)

Conventions for the Next.js web app in this folder. For repo-wide setup
(monorepo layout, the mobile app, the `dev.sh` launcher) start at the
[root README](../README.md). For day-one setup of *just* this folder see
[`README.md`](README.md).

## Stack summary

- Next.js 15 (App Router) + TypeScript (strict) + ESLint
- Tailwind CSS v4
- Prisma ORM with SQLite (dev)
- NextAuth credentials provider with bcrypt hashes
- Zod for runtime validation
- Tesseract.js for client-side receipt OCR (HEIC supported via `heic2any`)

Setup steps and available scripts live in [`README.md`](README.md). What
follows is just the conventions.

## Project layout

- `app/` – App Router pages and route handlers
  - UI pages in feature folders (e.g. `app/bills/...`)
  - REST endpoints in `app/api/.../route.ts` (documented in
    [`../docs/public-api-reference.md`](../docs/public-api-reference.md))
- `components/` – small, focused UI components (client or server)
- `lib/` – pure logic and utilities
  - `calc.ts` – bill split algorithm (deterministic rounding); the mobile
    app's `mobile/lib/utils/calc.dart` is a verbatim port. Keep them in sync.
  - `schemas.ts` – Zod schemas for request bodies
  - `db.ts` – Prisma client singleton
- `prisma/` – schema, migrations, and seed
- `scripts/` – local-dev tooling (e.g. `reset-password.ts`)

## Development conventions

- Use TypeScript strictly; avoid `any`.
- Keep components small and cohesive; move logic to `lib/` when possible.
- Never leave TODOs in mainline code; implement or file an issue.
- UI polish: responsive layouts, consistent spacing, no console warnings.

### Commit messages

Use conventional commits when possible:

- `feat: add item-level tax rate to Item`
- `fix: handle HEIC receipts in OCR`
- `docs: add architecture overview`
- `chore: bump prisma client`

### Branching & PRs

- Create feature branches off `main`: `feat/contacts-dialog`.
- Open small, focused PRs with a checklist and screenshots when UI changes.
- Include tests or repro steps for bug fixes.

## Database & migrations

- Update `prisma/schema.prisma` and generate a migration:
  ```bash
  pnpm prisma migrate dev --name <short-name>
  pnpm prisma generate
  ```
- Seed data lives in `prisma/seed.ts`.

## Algorithm notes

See `lib/calc.ts` for the authoritative implementation of splitting rules:

- Item pre-tax allocations use round-half-up with remainder distribution to the largest fractional parts (deterministic).
- Tax/tip pools: floor per participant then distribute leftover pennies by fractional part ordering (deterministic).
- Item-level tax mode supports per-item `taxRatePct` and `taxable` flag.

## Styling

- Tailwind utility classes + a few custom utility classes in `app/globals.css` (`.btn`, `.btn-primary`, `.chip`, etc.).
- Fonts: EB Garamond.

## Code review checklist

- [ ] Type-safe (no implicit `any`)
- [ ] Input validated via Zod
- [ ] No console warnings/errors in dev
- [ ] Clear UI/UX and responsive behavior
- [ ] Docs and comments updated when behavior changes


