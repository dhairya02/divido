# Divido — Mobile (Flutter)

A fully **offline**, single-user mobile app for splitting restaurant bills.
Built with Flutter, targets **iOS** and **Android** from a single codebase,
and stores everything in a local SQLite database on the device.

> No accounts. No servers. No internet required. Your data never leaves your phone.

## Status

| Concern             | State                                                                         |
|---------------------|-------------------------------------------------------------------------------|
| Build               | ✅ `flutter build ios` and `flutter build apk` both succeed                    |
| Static analysis     | ✅ `flutter analyze` — 0 issues                                                |
| Tests               | ✅ `flutter test` — split-calculator parity vs `web/lib/calc.ts`               |
| iOS deployment      | iOS 15.5+ (Podfile pin)                                                       |
| Android min SDK     | API 21 (Android 5.0)                                                          |
| On-device receipt AI| Apple Foundation Models on iOS 26+ — see [Receipt scanning](#receipt-scanning) |

## Prerequisites

- **Flutter SDK** 3.11+ on `PATH` (`flutter doctor` should be clean for the
  platforms you intend to build for)
- **iOS** builds: macOS + Xcode 16+ (Xcode 17 unlocks the on-device
  Foundation Models pipeline). CocoaPods is installed by Flutter.
- **Android** builds: Android SDK with API 21+ and a recent build-tools
  release; the Gradle wrapper checked into `android/` handles the rest.

## Features

- One-time onboarding to capture your display name (auto-creates a "self" contact)
- Browse and create bills, manage venue + tax/tip/fee rates
- Add items, pick participants, assign per-item shares with a chip grid
- One-tap split calculation using the same round-half-up logic the web app uses
- **Receipt scanning** that prefers Apple's on-device LLM (iOS 26+) and falls
  back to Gemini or basic OCR when it isn't available — see
  [Receipt scanning](#receipt-scanning) below
- Manage contacts (create / edit / delete) — the "you" contact is protected
- Import people straight from your phone's address book (with permission) — duplicates are detected automatically and nothing leaves the device
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
│   │   ├── local_repository.dart      # Typed CRUD + calculate over the DB
│   │   ├── device_contacts.dart       # Wraps flutter_contacts (permission + read)
│   │   ├── receipt_scanner.dart       # Three-tier receipt OCR dispatcher
│   │   ├── apple_receipt_scanner.dart # iOS-only: Vision OCR + Foundation Models
│   │   └── gemini_receipt_scanner.dart # Google Gemini multimodal fallback
│   ├── state/profile_state.dart       # ChangeNotifier for display name + self contact
│   ├── utils/
│   │   ├── calc.dart                  # Round-half-up split calculation
│   │   └── money.dart                 # Cents ↔ display formatting + parsing
│   ├── widgets/
│   │   ├── brand_logo.dart            # BrandMark + sticky BrandHeader
│   │   └── money.dart
│   └── screens/                       # Welcome, Home, BillDetail, NewBill, Contacts, ImportContacts, Account
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
flutter run                                # picks a connected device or simulator
flutter run --dart-define=GEMINI_API_KEY=… # optional, enables tier-2 OCR
```

Or from the repo root, in a single terminal:

```bash
./scripts/dev.sh                  # equivalent to `flutter run` in mobile/
./scripts/dev.sh -d "iPhone 16"   # extra args go straight through to Flutter
```

When prompted for a device, pick an iOS simulator, Android emulator, or
connected hardware. To verify the on-device receipt scanner you'll need a
physical iPhone with Apple Intelligence enabled — the iOS Simulator does
**not** ship Foundation Models.

## Useful commands

| Command                     | What it does                                            |
|-----------------------------|---------------------------------------------------------|
| `flutter pub get`           | Resolve dependencies                                    |
| `flutter analyze`           | Static analysis (must stay at 0 issues)                 |
| `flutter test`              | Run unit tests (calc parity vs the web lives here)      |
| `flutter run`               | Build & run on the selected device                      |
| `flutter build ios`         | Release build for iOS                                   |
| `flutter build apk`         | Release build for Android                               |
| `flutter build appbundle`   | Android App Bundle (Play Store upload)                  |

## Receipt scanning

Tap **Scan receipt** on the new-bill or bill-detail screen, point your camera
at a paper receipt, and Divido extracts the line items, tax, tip, and grand
total straight into the review sheet — no typing.

The scanner tries three engines in priority order and silently falls through
to the next on failure, so you always get *something* back:

| Tier | Engine                                              | Where it runs            | When it's used                                                                         |
|------|-----------------------------------------------------|--------------------------|----------------------------------------------------------------------------------------|
| 1    | **Apple Vision + Foundation Models**                | On-device, iOS 26+       | iPhone 15 Pro / iPhone 16+ / Apple Silicon iPad with Apple Intelligence enabled        |
| 2    | **Google Gemini 2.5 Flash** (multimodal)            | Cloud (HTTPS)            | A Gemini API key is set (`--dart-define=GEMINI_API_KEY=…` or in **Account → API key**) |
| 3    | **ML Kit text recognition + heuristic parser**      | On-device, all platforms | Always available — used as the universal safety net                                    |

The `ScanReviewSheet` lets the user verify, rename, re-price, or remove items
before they're attached to the bill, so an imperfect parse is never destructive.

### Why prefer Apple Foundation Models?

On supported devices the Apple path is **free, offline, private, and faster
than the cloud round-trip**:

1. `VNRecognizeTextRequest` (Vision) extracts the receipt text. It's
   generally more accurate on iOS than the cross-platform ML Kit recognizer,
   especially for low-contrast thermal-paper receipts.
2. The OCR text is fed to a `LanguageModelSession` with a typed
   `@Generable ParsedReceipt` Swift struct. Foundation Models enforces the
   schema during generation, so the output is guaranteed-shaped — no JSON
   repair, no regex parsing, no hallucinated fields.

The native bridge lives in `mobile/ios/Runner/AppDelegate.swift` and is
gated by `#if canImport(FoundationModels)` + `@available(iOS 26.0, *)`. On
older Xcode SDKs and older iPhones the file still builds; the path simply
reports "unavailable" at runtime and tier 2 / 3 takes over.

### Configuring the Gemini fallback (optional)

If you want a high-quality cross-platform fallback (and on devices without
Apple Intelligence, this becomes the primary path), provide a Gemini API key
either at build time:

```bash
flutter run --dart-define=GEMINI_API_KEY=ya29...
```

…or paste one into **Account → Gemini API key** at runtime — it lives in
the local `settings` table and never leaves the device except in the request
to Google.

If neither is configured, the app skips tier 2 and goes straight from Apple
(when available) to the on-device ML Kit parser.

## Where is my data?

It lives in a single SQLite file inside the app's sandbox:

- **iOS**: `Documents/divido.db` inside the app container
- **Android**: `databases/divido.db` inside the app's private storage

Uninstalling the app deletes the database. There's no automatic backup or sync; if you want to wipe it without uninstalling, use **Account → Reset all data**.

## Relationship to the web app

The web app (`web/`) is a separate, multi-user, server-hosted version of Divido with auth, OCR (Tesseract.js), and a shared database. The mobile app intentionally does NOT call any of its APIs — it's a self-contained reimplementation of the same bill-splitting model, with its own three-tier on-device receipt scanner described above.

The Dart `calculateSplit` in `lib/utils/calc.dart` is a port of `web/lib/calc.ts` and uses identical rounding rules, so the totals match the web version to the cent.
