# Divido — Mobile (Flutter)

A fully **offline**, single-user mobile app for splitting restaurant bills. Built with Flutter, targets **iOS** and **Android** from a single codebase, and stores all data in a local SQLite database on the device.

> No accounts. No servers. No internet required. Your data never leaves your phone.

## Features

- One-time onboarding to capture your display name (auto-creates a "self" contact)
- Browse and create bills, manage venue + tax/tip/fee rates
- Add items, pick participants, assign per-item shares with a chip grid
- One-tap split calculation using the same round-half-up logic the web app uses
- Manage contacts (create / edit / delete) — the "you" contact is protected
- Account screen with stats and a destructive **Reset all data** option
- Works completely offline; no `localhost`, no LAN config, no auth screen

## Architecture

```
mobile/
├── assets/images/divido-logo.png      # Shared brand logo (copied from packages/ui-assets)
├── lib/
│   ├── main.dart                      # Theme, providers, onboarding gate
│   ├── theme/brand.dart               # BrandColors + buildBrandTheme() (mirrors the website)
│   ├── models/{contact,bill}.dart     # Plain Dart data classes
│   ├── services/
│   │   ├── local_db.dart              # SQLite schema + opener (sqflite)
│   │   └── local_repository.dart      # Typed CRUD + calculate over the DB
│   ├── state/profile_state.dart       # ChangeNotifier for display name + self contact
│   ├── utils/
│   │   ├── calc.dart                  # Round-half-up split calculation
│   │   └── money.dart                 # Cents ↔ display formatting + parsing
│   ├── widgets/
│   │   ├── brand_logo.dart            # BrandMark + sticky BrandHeader
│   │   └── money.dart
│   └── screens/                       # Welcome, Home, BillDetail, NewBill, Contacts, Account
└── test/calc_test.dart                # Verifies the split calculator
```

## Brand & design language

The mobile UI uses the same tokens as the web app (single source of truth in
[`packages/ui-assets/README.md`](../packages/ui-assets/README.md) and
[`web/app/globals.css`](../web/app/globals.css)).

| Token       | Value     | Where it's used                               |
|-------------|-----------|-----------------------------------------------|
| `primary`   | `#6F8BFF` | Header bar, AppBar, selected chips, focus ring|
| `secondary` | `#C77DFF` | Primary action buttons, FAB                   |
| `accent`    | `#E6FDA3` | "Divido" wordmark on the brand header         |
| `muted`     | `#B794D9` | Soft accents                                  |

Typography is **EB Garamond** (serif), loaded via `google_fonts`, matching the
web body font. The shared brand logo lives at `assets/images/divido-logo.png`
(copied from `packages/ui-assets/`) and is rendered through `BrandMark` /
`BrandHeader` so any future logo swap is a one-line asset replacement.

### Data model (SQLite, on-device)

| Table              | Purpose                                          |
|--------------------|--------------------------------------------------|
| `contacts`         | People you split bills with (one row is "you")   |
| `bills`            | A bill: title, venue, subtotal, tax/tip/fee rates|
| `items`            | Line items belonging to a bill                   |
| `bill_participants`| Contact↔bill join — who's on this bill           |
| `item_shares`      | Per-item weight per participant                  |
| `settings`         | Key/value (e.g. `display_name`, `self_contact_id`) |

The schema mirrors the Prisma schema in `web/prisma/` minus the multi-user
`User`/sessions/passwords tables — those don't apply on a single device.

## Getting started

```bash
cd mobile
flutter pub get
flutter run
```

Or from the repo root, in a single terminal:

```bash
./scripts/dev.sh
```

When prompted for a device, pick an iOS simulator, Android emulator, or a connected device.

## Useful commands

```bash
flutter analyze   # static analysis (currently 0 issues)
flutter test      # run unit tests (split-calculator included)
flutter run       # run on the selected device
flutter build ios # release build for iOS
flutter build apk # release build for Android
```

## Where is my data?

It lives in a single SQLite file inside the app's sandbox:

- **iOS**: `Documents/divido.db` inside the app container
- **Android**: `databases/divido.db` inside the app's private storage

Uninstalling the app deletes the database. There's no automatic backup or sync; if you want to wipe it without uninstalling, use **Account → Reset all data**.

## Relationship to the web app

The web app (`web/`) is a separate, multi-user, server-hosted version of Divido with auth, OCR, and a shared database. The mobile app intentionally does NOT call any of its APIs — it's a self-contained reimplementation of the same bill-splitting model.

The Dart `calculateSplit` in `lib/utils/calc.dart` is a port of `web/lib/calc.ts` and uses identical rounding rules, so the totals match the web version to the cent.
