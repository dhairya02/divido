# Shared Packages

This directory contains shared code, contracts, and assets used by both the web and iOS applications.

## Structure

- **API Contracts**: TypeScript/Swift-compatible data models and API endpoint definitions
- **Utility Functions**: Shared business logic that can be used across platforms
- **Type Definitions**: Common interfaces and types

## API Models

Based on the Prisma schema, the following core models are shared:

### User
- Authentication and profile information

### Contact
- People involved in bill splitting
- Fields: name, email, phone, venmo, cashapp

### Bill
- Core bill information
- Fields: title, venue, subtotalCents, taxRatePct, tipRatePct, convenienceFeeRatePct
- Relations: items, participants, paidBy

### Item
- Individual items on a bill
- Fields: name, priceCents, quantity, taxable, taxRatePct
- Relations: shares

### BillParticipant
- Links contacts to bills
- Relations: shares

### ItemShare
- Defines how items are split
- Fields: weight (multiplier for splitting)
- Relations: item, participant

## API Endpoints

All endpoints return JSON and use standard HTTP methods:

### Authentication
- `POST /api/register` - Create account
- `POST /api/auth/signin` - Login
- `POST /api/auth/signout` - Logout

### Bills
- `GET /api/bills` - List all bills
- `POST /api/bills` - Create new bill
- `GET /api/bills/[id]` - Get bill details
- `PATCH /api/bills/[id]` - Update bill
- `DELETE /api/bills/[id]` - Delete bill
- `GET /api/bills/[id]/calc` - Calculate bill split

### Items
- `POST /api/bills/[id]/items` - Add item
- `PATCH /api/bills/[id]/items` - Update item
- `PUT /api/bills/[id]/items` - Upsert share
- `DELETE /api/bills/[id]/items` - Delete item

### Participants
- `POST /api/bills/[id]/participants` - Add participant

### Contacts
- `GET /api/contacts` - List contacts
- `POST /api/contacts` - Create contact
- `GET /api/contacts/[id]` - Get contact
- `PATCH /api/contacts/[id]` - Update contact
- `DELETE /api/contacts/[id]` - Delete contact

### User Profile
- `GET /api/me` - Get current user
- `GET /api/me/contact` - Get user contact
- `GET /api/me/stats` - Get user stats
- `PATCH /api/me/profile` - Update profile
- `PATCH /api/me/contact` - Update contact info
- `POST /api/me/password` - Change password
- `DELETE /api/me` - Delete account

### Balances
- Calculated client-side from bills and participants

