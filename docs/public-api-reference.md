# Public API, Library, and Component Reference

This document describes every public HTTP API, exported library function, and reusable UI component available in the project. It is intended for engineers who integrate with the backend or extend the React frontend. Each section includes behavior notes, request/response shapes, and usage examples.

## Overview

- **Base URL:** All endpoints are served from the Next.js application origin (e.g. `https://your-domain.example/api`).
- **Authentication:** Endpoints marked *Auth required* expect a valid NextAuth session cookie. Requests from unauthenticated users receive either `401 Unauthorized` or fall back to safe defaults (see individual notes).
- **Content type:** JSON payloads must be sent with `Content-Type: application/json`.
- **Error model:** Handlers return `400` for validation failures (`{ "error": "message" }`), `401` for unauthenticated access, `403` for forbidden operations, and `404` when the resource is missing.
- **Database:** Persistence is handled via Prisma against the schema defined in `prisma/schema.prisma`.

## HTTP API Endpoints

### Authentication & Account Lifecycle

#### `POST /api/register`

- **Auth:** Not required.
- **Description:** Registers a new password-based account and creates a matching contact record.
- **Request body:**

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | Yes | Display name stored on the `User` and initial contact. |
| `email` | string (email) | Yes | Stored lowercased; must be unique. |
| `password` | string (min 8 chars) | Yes | Bcrypt-hashed before storage. |

- **Successful response (200):** `{ "id": "user_cuid" }`
- **Failure cases:** `400` if the email already exists or validation fails.
- **Example:**

```bash
curl -X POST https://app.example.com/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Jamie","email":"jamie@example.com","password":"SuperSecret1"}'
```

#### `GET /api/auth/[...nextauth]` & `POST /api/auth/[...nextauth]`

- **Auth:** Handled by NextAuth; no direct consumption required.
- **Description:** Entry points for NextAuth’s credential flow. The credentials provider validates against stored password hashes and enriches sessions with the Prisma user ID.
- **Notes:** Exported as both `GET` and `POST` handlers for compatibility with NextAuth’s client helpers.

#### `DELETE /api/me`

- **Auth:** Required.
- **Description:** Permanently deletes the authenticated user, associated contacts, bills, and dependent records in a safe order.
- **Response (200):** `{ "ok": true }`
- **Failure cases:** `401` if not signed in, `500` if cascading deletes fail.
- **Usage tip:** This action is irreversible; confirm intent with the user before calling.

#### `GET /api/me/stats`

- **Auth:** Optional (returns zeroed stats when unauthenticated).
- **Description:** Returns counts of the signed-in user’s bills and contacts plus profile metadata.
- **Response (200):**

```json
{
  "bills": 5,
  "contacts": 12,
  "name": "Jamie",
  "email": "jamie@example.com"
}
```

### Profile & Credentials

#### `GET /api/me/contact`

- **Auth:** Optional.
- **Description:** Fetches the contact record representing the current user (chosen by matching email, then name).
- **Response (200):** Either `null` or `{ "id", "name", "email", "phone", "venmo", "cashapp" }`.

#### `PATCH /api/me/contact`

- **Auth:** Required.
- **Description:** Creates or updates the self-contact using `contactUpdateSchema` validation.
- **Request body fields:** Any subset of `name`, `email`, `phone`, `venmo`, `cashapp` (strings; empty strings are stripped to `undefined`).
- **Response (200):** Updated contact JSON.

#### `POST /api/me/password`

- **Auth:** Required (credentialed users only).
- **Description:** Changes the user’s password after verifying the current password.
- **Request body:** `{ "current": string, "next": string }`
- **Responses:**
  - `200` `{ "ok": true }` on success.
  - `400` if no password exists, current password is wrong, or body is invalid.

#### `PATCH /api/me/profile`

- **Auth:** Required.
- **Description:** Updates the user’s display name and synchronizes the self-contact that shares the same email.
- **Request body:** `{ "name": string }`
- **Response (200):** `{ "ok": true }`

### Contacts

#### `GET /api/contacts`

- **Auth:** Optional. Returns an empty list for guests.
- **Description:** Lists non-temporary contacts for the authenticated user ordered by `name`.
- **Response (200):** `Contact[]`

#### `POST /api/contacts`

- **Auth:** Required.
- **Description:** Creates a contact with `contactCreateSchema` validation. Duplicate emails return the existing contact.
- **Request body fields:**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | Yes | Display name. |
| `email` | string | Optional | Empty string coerced to `undefined`. |
| `phone` | string | Optional | Empty string removed. |
| `venmo` | string | Optional | Empty string removed. |
| `cashapp` | string | Optional | Empty string removed. |
| `isTemporary` | boolean | Optional | Defaults to `false`. |

- **Response:** `201` with the created contact JSON.
- **Example:**

```bash
curl -X POST https://app.example.com/api/contacts \
  -H "Content-Type: application/json" \
  --cookie "next-auth.session-token=..." \
  -d '{"name":"Alex Kim","email":"alex@example.com","phone":"555-0102"}'
```

#### `PATCH /api/contacts/:id`

- **Auth:** Required.
- **Description:** Updates a contact via `contactUpdateSchema`. If the contact belongs to the logged-in user and emails match, the user’s profile name is also updated.
- **Response:** Updated contact JSON.

#### `DELETE /api/contacts/:id`

- **Auth:** Required.
- **Description:** Deletes a contact after cleaning dependent bill participants and item shares. Cannot delete the contact linked to the user’s own email.
- **Responses:** `200` `{ "ok": true }`, `400` if attempting to delete the self-contact, `403` if the contact belongs to another user.

#### `POST /api/contacts/bulk-delete`

- **Auth:** *Not enforced.* Callers must ensure only authorized deletions.
- **Description:** Deletes contacts whose IDs are provided, along with their participant records.
- **Request body:** `{ "ids": string[] }`
- **Response:** `{ "deleted": number }`
- **Note:** Because authentication is not enforced in the handler, only expose this route to trusted callers.

### Bills

#### `GET /api/bills`

- **Auth:** Optional (unauthenticated requests return the global bill list, which is effectively empty when records are scoped by `userId`).
- **Description:** Lists bills ordered by creation date, selecting summary fields.
- **Response (200):**

```json
[
  {
    "id": "bill_123",
    "title": "Team Dinner",
    "venue": "The Gem Saloon",
    "date": "2025-08-26T04:15:00.000Z",
    "subtotalCents": 7200,
    "taxRatePct": 8.875,
    "tipRatePct": 20,
    "convenienceFeeRatePct": 3,
    "currency": "USD",
    "paidByContactId": "contact_abc"
  }
]
```

#### `POST /api/bills`

- **Auth:** Required.
- **Description:** Creates a bill and optional participant links. Validated by `billCreateSchema`.
- **Request fields:**

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `title` | string | Yes | Bill title. |
| `venue` | string | No | Venue name. |
| `subtotalCents` | integer | Yes | Sum of item prices in cents. |
| `taxRatePct` | number (≥0) | Yes | Default tax rate. |
| `tipRatePct` | number (≥0) | Yes | Default tip percentage. |
| `currency` | string | No, defaults to `USD`. |
| `taxMode` | `"GLOBAL"` or `"ITEM"` | No, defaults to `GLOBAL`. |
| `participantContactIds` | string[] | No | Contact IDs to attach as participants. |
| `convenienceFeeRatePct` | number (≥0) | No | Convenience fee rate. |
| `paidByContactId` | string | No | Contact designated as payer. |

- **Response:** `201` `{ "id": "bill_cuid" }`

#### `GET /api/bills/:id`

- **Auth:** Not enforced (exposes bill contents by ID).
- **Description:** Returns bill details, items, participants (with related contacts), and item share weights.
- **Successful response:**

```json
{
  "bill": {
    "id": "bill_123",
    "title": "Team Dinner",
    "subtotalCents": 7200,
    "taxRatePct": 8.875,
    "tipRatePct": 20,
    "convenienceFeeRatePct": 3,
    "currency": "USD",
    "taxMode": "GLOBAL",
    "items": [
      {
        "id": "item_1",
        "name": "Nachos",
        "priceCents": 1800,
        "quantity": 1,
        "taxable": true,
        "taxRatePct": 8.875
      }
    ],
    "participants": [ /* raw billParticipant rows with contact relation */ ]
  },
  "participants": [
    { "id": "bp_1", "name": "Alex Kim", "contactId": "contact_abc" }
  ],
  "items": [
    { "id": "item_1", "billId": "bill_123", "name": "Nachos", "priceCents": 1800, "quantity": 1, "taxable": true, "taxRatePct": 8.875 }
  ],
  "shares": [
    { "id": "share_1", "itemId": "item_1", "participantId": "bp_1", "weight": 1 }
  ]
}
```

- **Failure cases:** `404` if the bill ID does not exist.

#### `DELETE /api/bills/:id`

- **Auth:** Not enforced.
- **Description:** Deletes the bill and cascades deletion to items, participants, and item shares.
- **Response:** `{ "ok": true }`

#### `PATCH /api/bills/:id`

- **Auth:** Not enforced.
- **Description:** Updates monetary metadata (`paidByContactId`, `subtotalCents`, rate percentages). Validates numeric ranges before persisting.
- **Request body fields:** Any subset of the permitted properties; omitting all returns `400`.
- **Response:** `{ "ok": true }`

#### `POST /api/bills/:id/items`

- **Auth:** Not enforced.
- **Description:** Adds an item to the bill using `itemCreateSchema` validation.
- **Response:** `201` with the created `Item`.

#### `PUT /api/bills/:id/items`

- **Auth:** Not enforced.
- **Description:** Upserts an item share (participant weight) using `shareUpsertSchema`. Rejects if the item does not belong to the bill.
- **Request body:** `{ "itemId": string, "participantId": string, "weight": number }`
- **Response:** Updated or created share JSON.

#### `PATCH /api/bills/:id/items`

- **Auth:** Not enforced.
- **Description:** Updates item fields (`name`, `priceCents`, `taxable`, `taxRatePct`, `quantity`).
- **Request body:** `{ "itemId": string, ...updates }`
- **Response:** Updated item JSON.

#### `DELETE /api/bills/:id/items`

- **Auth:** Not enforced.
- **Description:** Deletes an item and its shares after verifying ownership.
- **Request body:** `{ "itemId": string }`
- **Response:** `{ "ok": true }`

#### `POST /api/bills/:id/participants`

- **Auth:** Not enforced.
- **Description:** Adds a contact to the bill’s participants. Payload: `{ "contactId": string, "note"?: string }`.
- **Response:** `201` with the new bill participant record.

#### `GET /api/bills/:id/calc`

- **Auth:** Not enforced.
- **Description:** Computes splits using `calculateSplit`. Validates there are items, totals match the bill subtotal, and each item has shares.
- **Response (200):**

```json
{
  "billTotals": {
    "subtotalCents": 7200,
    "taxCents": 639,
    "tipCents": 1440,
    "convenienceFeeCents": 216,
    "grandTotalCents": 9495
  },
  "participants": [
    {
      "participantId": "bp_1",
      "name": "Alex Kim",
      "preTaxCents": 3600,
      "taxCents": 319,
      "tipCents": 720,
      "convenienceFeeCents": 108,
      "totalOwedCents": 4747,
      "contactId": "contact_abc"
    }
  ],
  "byItem": [
    {
      "itemId": "item_1",
      "allocations": [
        { "participantId": "bp_1", "cents": 1800 }
      ]
    }
  ]
}
```

- **Failure cases:** `400` with specific messages for missing items, subtotal mismatches, or items without shares; `404` if the bill is missing.

#### `POST /api/bills/clear`

- **Auth:** Not enforced.
- **Description:** Deletes *all* bills and their dependent records. Returns `{ "deleted": number }` (count of bills removed).
- **Caution:** Restrict this endpoint to trusted contexts such as test fixtures or admin tooling.

### Utility Endpoints

- No additional standalone utility endpoints beyond those listed above.

## Library Modules

### `lib/auth.ts`

- **Exports:** `authOptions: NextAuthOptions`
- **Purpose:** Central NextAuth configuration using the Prisma adapter and a credentials provider. On sign-in, the user ID is attached to JWT and session payloads so request handlers can read `(session.user as any).id`.
- **Usage example:**

```ts
import NextAuth from "next-auth";
import { authOptions } from "@/lib/auth";

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

### `lib/db.ts`

- **Exports:** `prisma: PrismaClient`
- **Purpose:** Provides a singleton Prisma client across hot reloads. The instance logs warnings and errors by default.
- **Usage example:**

```ts
import { prisma } from "@/lib/db";

const bills = await prisma.bill.findMany({ where: { userId } });
```

### `lib/calc.ts`

- **Exports:**
  - `calculateSplit(input: CalcInput): CalcOutput`
  - `CalcInput`, `CalcOutput` types.
- **Purpose:** Deterministically allocates item costs, tax, tip, and optional convenience fees across participants using round-half-up arithmetic and stable sorting.
- **Key behaviors:**
  - Validates that every item has at least one share.
  - Ensures allocations sum exactly to the grand total via remainder distribution.
  - Supports a global tax rate or per-item tax rates (`taxMode: "ITEM"`).
- **Usage example:**

```ts
import { calculateSplit } from "@/lib/calc";

const result = calculateSplit({
  items: [
    { id: "item_1", priceCents: 1800, taxable: true, taxRatePct: 8.875 },
    { id: "item_2", priceCents: 5400 }
  ],
  participants: [
    { id: "p1", name: "Alex" },
    { id: "p2", name: "Taylor" }
  ],
  shares: [
    { itemId: "item_1", participantId: "p1", weight: 1 },
    { itemId: "item_1", participantId: "p2", weight: 1 },
    { itemId: "item_2", participantId: "p2", weight: 1 }
  ],
  taxRatePct: 8.875,
  tipRatePct: 20,
  convenienceFeeRatePct: 3
});

console.log(result.participants[0].totalOwedCents); // Participant OOP cents
```

### `lib/currency.ts`

- **Exports:** `formatCents(amountCents: number, currency?: string): string`
- **Purpose:** Wrapper around `Intl.NumberFormat` that converts integer cents into a localized currency string (default `USD`).
- **Example:** `formatCents(1234) // "$12.34"`

### `lib/schemas.ts`

- **Exports:** Zod schemas and TypeScript inference types:
  - `contactCreateSchema`, `ContactCreateInput`
  - `contactUpdateSchema`, `ContactUpdateInput`
  - `billCreateSchema`, `BillCreateInput`
  - `itemCreateSchema`, `ItemCreateInput`
  - `itemUpdateSchema`, `ItemUpdateInput`
  - `shareUpsertSchema`, `ShareUpsertInput`
- **Purpose:** Centralized validation for API payloads, including transformations that strip empty strings.
- **Usage example:**

```ts
import { billCreateSchema } from "@/lib/schemas";

const payload = billCreateSchema.parse(await req.json());
```

### `lib/utils.ts`

- **Exports:**
  - `roundHalfUp(value: number): number` – Bankers rounding that always rounds halves away from zero.
  - `fractionalPart(value: number): number` – Returns the fractional component of a number.
  - `assert(condition: unknown, message: string): asserts condition` – Throws if the condition is falsy.
  - `stableSortBy<T>(arr: T[], selector: (x: T) => number | string): T[]` – Stable sort implementation that preserves relative order of equal keys.
- **Example:**

```ts
import { stableSortBy } from "@/lib/utils";

const sorted = stableSortBy(users, (u) => u.lastName);
```

## UI Components

Each component below lives in `components/` and is a client component unless noted.

### `AccountMenu`

- **Description:** Circular avatar button that toggles an account dropdown containing stats and navigation links. Fetches `/api/me/stats` on mount.
- **Props:** None.
- **Usage:**

```tsx
import AccountMenu from "@/components/AccountMenu";

export function Header() {
  return (
    <header className="flex justify-end">
      <AccountMenu />
    </header>
  );
}
```

### `AddContactDialog`

- **Description:** Modal form for creating contacts. Supports guest mode by storing entries in `sessionStorage` when no session exists.
- **Props:**

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| `open` | boolean | Yes | Controls visibility. |
| `onClose` | `() => void` | Yes | Dismiss handler. |
| `onAdded` | `() => Promise<void> \| void` | Yes | Invoked after a contact is created. |

- **Usage:**

```tsx
const [open, setOpen] = useState(false);

<>
  <button className="btn" onClick={() => setOpen(true)}>Add contact</button>
  <AddContactDialog
    open={open}
    onClose={() => setOpen(false)}
    onAdded={() => refetchContacts()}
  />
</>
```

### `AlertDialog`

- **Description:** Generic modal for one-button notices.
- **Props:** `open`, `title?`, `message?`, `buttonText?`, `onClose`.
- **Usage:**

```tsx
<AlertDialog open={showNotice} message="Invite sent." onClose={() => setShowNotice(false)} />
```

### `ConfirmDialog`

- **Description:** Two-button confirmation modal.
- **Props:** `open`, `title?`, `message?`, `confirmText?`, `cancelText?`, `onConfirm`, `onCancel`.
- **Usage:**

```tsx
<ConfirmDialog
  open={confirming}
  message="Delete this bill?"
  confirmText="Delete"
  onConfirm={handleDelete}
  onCancel={() => setConfirming(false)}
/> 
```

### `ContactDetailDialog`

- **Description:** Read-only modal that surfaces contact metadata.
- **Props:** `open`, `contact` (object or `null`), `onClose`.
- **Usage:**

```tsx
<ContactDetailDialog open={!!selected} contact={selected} onClose={() => setSelected(null)} />
```

### `EditContactDialog`

- **Description:** Modal for editing an existing contact. Updates via `/api/contacts/:id`.
- **Props:**

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| `open` | boolean | Yes | Controls visibility. |
| `contact` | `{ id: string; name: string; email?: string; phone?: string; venmo?: string; cashapp?: string } \| null` | Yes | Populates form fields. |
| `onClose` | `() => void` | Yes | Dismiss handler. |
| `onSaved` | `() => Promise<void> \| void` | Yes | Invoked after save completes. |

- **Usage:**

```tsx
<EditContactDialog
  open={!!contact}
  contact={contact}
  onClose={() => setContact(null)}
  onSaved={refetchContacts}
/> 
```

### `HistoryNav`

- **Description:** Renders back/forward buttons tied to Next.js router history.
- **Props:** None.
- **Usage:** `<HistoryNav />`

### `ItemShareEditor`

- **Description:** Chip-based control for assigning weights to participants for a single item.
- **Props:**

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| `itemId` | string | Yes | Item being edited. |
| `participants` | `{ id: string; name: string }[]` | Yes | Available participants. |
| `existingShares` | `{ itemId: string; participantId: string; weight: number }[]` | Yes | Current weights. |
| `billId` | string | Yes | Bill ID used in API calls. |
| `onSaved` | `() => void` | No | Callback after saving. |

- **Usage:**

```tsx
<ItemShareEditor
  itemId={item.id}
  participants={billParticipants}
  existingShares={shares.filter((s) => s.itemId === item.id)}
  billId={bill.id}
  onSaved={refetchShares}
/> 
```

### `ItemShareMatrix`

- **Description:** Editable grid for bulk editing item share weights across all items/participants. Performs diffing to only submit changed cells.
- **Props:**

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| `items` | `{ id: string; name: string; priceCents: number }[]` | Yes | Items to display. |
| `participants` | `{ id: string; name: string }[]` | Yes | Participants displayed as columns. |
| `shares` | `{ itemId: string; participantId: string; weight: number }[]` | Yes | Existing shares. |
| `billId` | string | Yes | Bill ID for API calls. |
| `onSaved` | `() => Promise<void> \| void` | No | Called after save success. |

- **Usage:**

```tsx
<ItemShareMatrix
  items={bill.items}
  participants={simpleParticipants}
  shares={shares}
  billId={bill.id}
  onSaved={refetchBill}
/> 
```

### `Logo`

- **Description:** Image component that swaps to `/favicon.ico` if the branded logo fails to load.
- **Props:** `className?`
- **Usage:** `<Logo className="h-8" />`

### `Modal`

- **Description:** Portal-based modal foundation with backdrop handling and `Escape` key support.
- **Props:** `open`, `title?`, `children?`, `onClose`, `actions?`.
- **Usage:**

```tsx
<Modal open={isOpen} title="Example" onClose={close} actions={<button onClick={close}>Close</button>}>
  Modal content here.
</Modal>
```

### `Money`

- **Description:** Formats integer cents using `formatCents`.
- **Props:** `cents` (number, required), `currency?` (defaults to `USD`).
- **Usage:** `<Money cents={subtotalCents} currency={bill.currency} />`

### `ParticipantPicker`

- **Description:** Searchable chip list for selecting contacts as bill participants. Supports temporary guest contacts.
- **Props:**

| Prop | Type | Required | Description |
| --- | --- | --- | --- |
| `selectedIds` | string[] | Yes | Currently selected contact IDs. |
| `onToggle` | `(contactId: string) => void` | Yes | Toggles selection. |
| `enableTemp` | boolean | No | Enables temporary participant input. |
| `onContactsChange` | `(contacts: Contact[]) => void` | No | Receives fetched contacts. |
| `onTempMapChange` | `(map: Record<string, string>) => void` | No | Receives mapping for temporary IDs. |

- **Usage:**

```tsx
<ParticipantPicker
  selectedIds={participantIds}
  onToggle={(id) => toggleParticipant(id)}
  enableTemp
  onTempMapChange={setTempParticipants}
/> 
```

### `Providers`

- **Description:** Wraps children in NextAuth’s `SessionProvider` to hydrate client components with session context.
- **Props:** `children` (ReactNode).
- **Usage:**

```tsx
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

### `ReceiptOCR`

- **Description:** Client-side OCR helper that accepts receipt images, runs Tesseract.js (with HEIC conversion fallback), and emits parsed line items.
- **Props:** `onItems: (items: { name: string; price: number }[]) => Promise<void> \| void`
- **Usage:**

```tsx
<ReceiptOCR onItems={async (items) => {
  // Convert parsed prices into bill items
  for (const item of items) {
    await addItemFromOCR(item);
  }
}} />
```

---

This reference should equip you to integrate with the backend APIs, reuse shared utility functions, and compose the provided UI components with confidence. Keep it alongside architectural notes in `ARCHITECTURE.md` for a complete view of the system.

