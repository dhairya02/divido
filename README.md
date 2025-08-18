Divido — a Next.js app to split bills fairly.

## Getting Started

Install dependencies:

```bash
pnpm install
```

Set up Prisma (SQLite) and seed data:

```bash
pnpm prisma migrate dev --name init
pnpm prisma db seed
```

Run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser.

You can start editing the app by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

### Notes

- API routes are under `/api/*` for contacts, bills, items, and calculation.
- Core split algorithm is in `lib/calc.ts` and guarantees penny-accurate totals with deterministic rounding.
