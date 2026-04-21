# Divido

Fair, precise restaurant-bill splitting — across web and mobile from a single
monorepo. The two apps share a design system, a calculation algorithm, and a
data model; everything else is intentionally separate so each platform can
follow its own ergonomics.

## What's in the box

| Path                | What it is                                                       | Status                       |
|---------------------|------------------------------------------------------------------|------------------------------|
| `web/`              | Next.js 15 + Prisma multi-user web app with auth and OCR         | ✅ Production-ready           |
| `mobile/`           | Flutter app (iOS + Android), fully offline, single-user, SQLite  | ✅ Production-ready           |
| `packages/shared/`  | API contract reference (used by both platforms)                  | Reference only               |
| `packages/ui-assets/` | Design tokens (colors, fonts, spacing) — single source of truth | Reference only               |
| `docs/`             | Long-form docs — start with `public-api-reference.md`            | Maintained alongside the web app |
| `scripts/dev.sh`    | One-shot launcher for mobile, web, or both                       | —                            |

The two apps are intentionally **not** tightly coupled: the mobile app does
not call the web backend. They share a model and an algorithm, not a runtime.

## Quick start

### Just the mobile app (most common)

```bash
./scripts/dev.sh
```

Picks the connected device / simulator, runs `flutter run` against `mobile/`.
Pass any `flutter run` argument straight through, e.g.:

```bash
./scripts/dev.sh -d "iPhone 16"
```

See [`mobile/README.md`](mobile/README.md) for prerequisites, the data model,
and the **on-device receipt scanner**
([Apple Foundation Models → Gemini → ML Kit](mobile/README.md#receipt-scanning)).

### Just the web app

```bash
cd web
pnpm install
pnpm prisma migrate dev      # first time only
pnpm prisma db seed          # optional sample data
pnpm dev                     # http://localhost:3000
```

See [`web/README.md`](web/README.md) for env setup, available scripts, and
common issues. The HTTP API is documented in
[`docs/public-api-reference.md`](docs/public-api-reference.md).

### Both at once

```bash
./scripts/dev.sh --web       # boots Next.js on :3000, then Flutter
./scripts/dev.sh --web-only  # just the web backend in the foreground
```

## Toolchain

| Tool          | Version              | Used for                                    |
|---------------|----------------------|---------------------------------------------|
| Node.js       | 20+ (tested 25)      | web                                         |
| pnpm          | 10+                  | web package manager                         |
| Flutter SDK   | 3.11+                | mobile                                      |
| Xcode         | 16+ (17 recommended) | mobile iOS builds; **17 unlocks the on-device Foundation Models pipeline** |
| Android SDK   | API 21+              | mobile Android builds                       |

The `mobile/` Podfile pins `iOS 15.5` as the deployment target, so older
iPhones still get the app — they just fall back to ML Kit / Gemini for
receipt scanning instead of the new Apple-Intelligence pipeline.

## Architecture at a glance

```
divido/
├── web/                    # Next.js 15, Prisma, NextAuth, Tailwind v4
│   ├── app/                # App-Router pages + /api route handlers
│   ├── components/         # React components (Money, ItemShare*, ReceiptOCR…)
│   ├── lib/                # calc.ts (split algorithm), schemas.ts (Zod), db.ts
│   ├── prisma/             # schema + migrations + seed (SQLite)
│   └── scripts/            # one-off tooling (e.g. reset-password)
│
├── mobile/                 # Flutter, single-user, fully offline
│   ├── lib/
│   │   ├── screens/        # Welcome, Home, BillDetail, NewBill, Contacts, Account…
│   │   ├── services/       # local_db, local_repository, device_contacts,
│   │   │                   # receipt_scanner (3-tier), apple_/gemini_receipt_scanner
│   │   ├── state/          # ChangeNotifier providers
│   │   ├── utils/          # calc.dart (port of web/lib/calc.ts), money.dart
│   │   ├── theme/          # brand tokens
│   │   └── widgets/        # BrandHeader, ScanReviewSheet, …
│   ├── ios/Runner/         # AppDelegate.swift hosts the FoundationModels bridge
│   └── test/               # unit tests (calc parity vs the web)
│
├── packages/
│   ├── shared/README.md    # Cross-platform API + model reference
│   └── ui-assets/README.md # Brand tokens (colors, type, spacing)
│
├── docs/
│   └── public-api-reference.md   # Authoritative HTTP API docs
│
└── scripts/dev.sh          # mobile / web / both
```

## Calculator: the one rule both apps must agree on

`web/lib/calc.ts` is the authoritative implementation; `mobile/lib/utils/calc.dart`
is a verbatim port verified by `mobile/test/calc_test.dart`. Any change to
the splitting algorithm needs to land in **both** files in the same PR, and
the parity test must keep passing.

## Receipt scanning at a glance

| Platform | Engine                                 | When it's used                                              |
|----------|----------------------------------------|-------------------------------------------------------------|
| Web      | Tesseract.js (client-side)             | Always                                                      |
| Mobile   | Apple Vision + Foundation Models LLM   | iOS 26+ on Apple-Intelligence-eligible devices              |
| Mobile   | Google Gemini 2.5 Flash (multimodal)   | When a Gemini API key is configured                         |
| Mobile   | ML Kit text recognition + heuristics   | Universal on-device fallback                                |

The mobile app picks the best engine available at runtime and falls through
on failure, so a scan never hard-errors. Full details live in
[`mobile/README.md#receipt-scanning`](mobile/README.md#receipt-scanning).

## Where to go next

- **Run the mobile app** → [`mobile/README.md`](mobile/README.md)
- **Run the web app** → [`web/README.md`](web/README.md)
- **Use the HTTP API** → [`docs/public-api-reference.md`](docs/public-api-reference.md)
- **Web architecture deep-dive** → [`web/ARCHITECTURE.md`](web/ARCHITECTURE.md)
- **Contribute to the web app** → [`web/CONTRIBUTING.md`](web/CONTRIBUTING.md)
- **Brand tokens** → [`packages/ui-assets/README.md`](packages/ui-assets/README.md)

## License

Private project — all rights reserved.
