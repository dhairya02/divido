# Web App Quick Start

## After Monorepo Restructuring

The web application has been moved into the `web/` directory as part of the monorepo setup. Follow these steps to run it:

### 1. Install Dependencies

```bash
cd web
pnpm install
```

### 2. Set Up Database

The `.env` file should already be configured with:
```
DATABASE_URL="file:./prisma/dev.db"
```

Generate Prisma client:
```bash
pnpm prisma generate
```

### 3. Run Migrations (if needed)

If the database is empty or needs migrations:
```bash
pnpm prisma migrate dev
```

### 4. Seed Database (optional)

```bash
pnpm seed
```

### 5. Start Development Server

```bash
pnpm dev
```

Or use the auto-open script:
```bash
pnpm dev:open
```

The app will be available at `http://localhost:3000`

## Common Issues

### "Cannot find module '@prisma/client'"
**Solution**: Run `pnpm prisma generate`

### "Environment variable not found: DATABASE_URL"
**Solution**: Ensure `.env` file exists in `web/` directory with correct path

### Build errors after moving files
**Solution**: Delete `.next` folder and rebuild:
```bash
rm -rf .next
pnpm dev
```

### Database connection errors
**Solution**: Check that `prisma/dev.db` exists. If not, run migrations:
```bash
pnpm prisma migrate dev
```

## Available Scripts

- `pnpm dev` - Start dev server with Turbopack
- `pnpm dev:open` - Start dev server and auto-open browser
- `pnpm build` - Build for production
- `pnpm start` - Start production server
- `pnpm lint` - Run ESLint
- `pnpm prisma:generate` - Generate Prisma client
- `pnpm prisma:migrate` - Run database migrations
- `pnpm seed` - Seed database with sample data

## Notes

- All functionality remains identical to before the monorepo restructure
- The database file is still at `web/prisma/dev.db`
- All components, pages, and API routes work exactly as before
- The only change is the directory structure for better organization alongside the iOS app

