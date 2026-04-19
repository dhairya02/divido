# RestaurantSplit - Monorepo

Fair, precise bill splitting across web and iOS platforms.

## Project Structure

```
RestaurantSplit/
├── web/                    # Next.js web application
│   ├── app/               # Next.js 15 app router pages
│   ├── components/        # React components
│   ├── lib/              # Utilities and business logic
│   ├── prisma/           # Database schema and migrations
│   └── public/           # Static assets
│
├── ios/                   # SwiftUI iOS application
│   ├── RestaurantSplit/  # Main app target
│   ├── Models/           # Swift data models
│   ├── Views/            # SwiftUI views
│   ├── ViewModels/       # View model layer
│   ├── Services/         # API client and utilities
│   └── Assets.xcassets/  # iOS assets and colors
│
├── mobile/                # Flutter mobile application (iOS + Android)
│   ├── lib/              # Dart sources (screens, services, state, models)
│   └── test/             # Unit tests including the calc-port verification
│
└── packages/             # Shared code and assets
    ├── shared/          # API contracts and models
    └── ui-assets/       # Design tokens, colors, fonts
```

## Getting Started

### Web Application

```bash
cd web
pnpm install
pnpm dev
```

The web app will be available at `http://localhost:3000`.

For auto-opening in browser:
```bash
pnpm dev:open
```

### iOS Application (SwiftUI)

1. Open `ios/RestaurantSplit.xcodeproj` in Xcode
2. Select a simulator or device
3. Build and run (⌘R)

**Requirements:**
- macOS 13.0+
- Xcode 15.0+
- iOS 17.0+ deployment target

### Mobile Application (Flutter — iOS + Android)

The mobile app is **fully offline** — it stores everything in a local SQLite
database on the device, so it doesn't need the Next.js backend at all.

```bash
./scripts/dev.sh         # just runs `flutter run` on mobile/
./scripts/dev.sh --web   # also boot the Next.js web app on :3000 (optional)
```

See [`mobile/README.md`](mobile/README.md) for the data model, where the
SQLite file lives on each platform, and testing instructions.

## Architecture

### Backend (Web)

- **Framework**: Next.js 15 with App Router
- **Database**: SQLite via Prisma ORM
- **Authentication**: NextAuth.js with credentials provider
- **API**: REST endpoints in `/api` routes

### Frontend (Web)

- **UI**: React 19 with Tailwind CSS 4
- **State**: React hooks and Context
- **Forms**: Native HTML5 validation
- **OCR**: Tesseract.js for receipt scanning

### iOS App

- **UI Framework**: SwiftUI
- **Architecture**: MVVM pattern
- **Networking**: URLSession with Combine
- **Storage**: Keychain for auth tokens
- **OCR**: Vision framework

## Shared Contracts

Both platforms use the same:
- API endpoint structure (see `packages/shared/README.md`)
- Data models (TypeScript interfaces → Swift Codable structs)
- Design system (colors, typography, spacing)

## Development Workflow

### Adding a New Feature

1. Define API contract in `packages/shared/`
2. Implement backend endpoint in `web/app/api/`
3. Build web UI in `web/app/` and `web/components/`
4. Create Swift models in `ios/Models/`
5. Implement iOS view model and UI

### Design System Updates

1. Update tokens in `packages/ui-assets/README.md`
2. Apply to web via Tailwind config
3. Update iOS asset catalog and extensions

## Testing

### Web
```bash
cd web
pnpm lint
# Add test command when tests are implemented
```

### iOS
```bash
cd ios
xcodebuild test -scheme RestaurantSplit -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment

### Web
- Deploy to Vercel or similar Node.js platform
- Ensure Prisma migrations are run on deploy

### iOS
- Build for TestFlight via Xcode Cloud or manual upload
- Requires Apple Developer account

## Contributing

See [CONTRIBUTING.md](web/CONTRIBUTING.md) for detailed guidelines.

## License

Private project - All rights reserved.

