-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Bill" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "venue" TEXT,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "subtotalCents" INTEGER NOT NULL,
    "taxRatePct" REAL NOT NULL DEFAULT 0,
    "tipRatePct" REAL NOT NULL DEFAULT 0,
    "convenienceFeeRatePct" REAL NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "taxMode" TEXT NOT NULL DEFAULT 'GLOBAL',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paidByContactId" TEXT,
    "userId" TEXT,
    CONSTRAINT "Bill_paidByContactId_fkey" FOREIGN KEY ("paidByContactId") REFERENCES "Contact" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Bill_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Bill" ("convenienceFeeRatePct", "createdAt", "currency", "date", "id", "paidByContactId", "subtotalCents", "taxMode", "taxRatePct", "tipRatePct", "title", "venue") SELECT "convenienceFeeRatePct", "createdAt", "currency", "date", "id", "paidByContactId", "subtotalCents", "taxMode", "taxRatePct", "tipRatePct", "title", "venue" FROM "Bill";
DROP TABLE "Bill";
ALTER TABLE "new_Bill" RENAME TO "Bill";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
