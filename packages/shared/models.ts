/**
 * Shared data models for RestaurantSplit
 * These interfaces mirror the Prisma schema and are used by both web and iOS
 */

export interface User {
  id: string;
  name: string | null;
  email: string | null;
  emailVerified: Date | null;
  image: string | null;
}

export interface Contact {
  id: string;
  name: string;
  email?: string | null;
  phone?: string | null;
  venmo?: string | null;
  cashapp?: string | null;
  createdAt: Date;
  isTemporary: boolean;
  userId?: string | null;
}

export interface Bill {
  id: string;
  title: string;
  venue?: string | null;
  date: Date;
  subtotalCents: number;
  taxRatePct: number;
  tipRatePct: number;
  convenienceFeeRatePct: number;
  currency: string;
  taxMode: 'GLOBAL' | 'ITEM';
  createdAt: Date;
  paidByContactId?: string | null;
  userId?: string | null;
}

export interface BillParticipant {
  id: string;
  billId: string;
  contactId: string;
  note?: string | null;
}

export interface Item {
  id: string;
  billId: string;
  name: string;
  priceCents: number;
  quantity: number;
  taxable: boolean;
  taxRatePct: number;
}

export interface ItemShare {
  id: string;
  itemId: string;
  participantId: string;
  weight: number;
}

// API Request/Response types

export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface CreateBillRequest {
  title: string;
  venue?: string;
  subtotalCents: number;
  taxRatePct: number;
  tipRatePct: number;
  convenienceFeeRatePct?: number;
  currency?: string;
  taxMode?: 'GLOBAL' | 'ITEM';
  participantContactIds?: string[];
  paidByContactId?: string;
}

export interface UpdateBillRequest {
  paidByContactId?: string;
  subtotalCents?: number;
  taxRatePct?: number;
  tipRatePct?: number;
  convenienceFeeRatePct?: number;
}

export interface CreateItemRequest {
  name: string;
  priceCents: number;
  quantity?: number;
  taxable?: boolean;
  taxRatePct?: number;
}

export interface UpdateItemRequest {
  itemId: string;
  name?: string;
  priceCents?: number;
  taxable?: boolean;
  taxRatePct?: number;
  quantity?: number;
}

export interface UpsertShareRequest {
  itemId: string;
  participantId: string;
  weight: number;
}

export interface CreateContactRequest {
  name: string;
  email?: string;
  phone?: string;
  venmo?: string;
  cashapp?: string;
  isTemporary?: boolean;
}

export interface UpdateContactRequest {
  name?: string;
  email?: string;
  phone?: string;
  venmo?: string;
  cashapp?: string;
}

export interface UpdateProfileRequest {
  name?: string;
}

export interface ChangePasswordRequest {
  current: string;
  next: string;
}

// Calculation response types

export interface ParticipantCalculation {
  participantId: string;
  contactId: string;
  name: string;
  preTaxCents: number;
  taxCents: number;
  tipCents: number;
  convenienceFeeCents: number;
  totalOwedCents: number;
}

export interface ItemAllocation {
  participantId: string;
  cents: number;
}

export interface ItemCalculation {
  itemId: string;
  name: string;
  allocations: ItemAllocation[];
}

export interface BillTotals {
  subtotalCents: number;
  taxCents: number;
  tipCents: number;
  convenienceFeeCents: number;
  grandTotalCents: number;
}

export interface CalculationResponse {
  participants: ParticipantCalculation[];
  byItem: ItemCalculation[];
  billTotals: BillTotals;
}

export interface CalculationError {
  error: string;
  itemsTotalCents?: number;
  billSubtotalCents?: number;
}

// Extended response types with relations

export interface BillWithDetails {
  bill: Bill;
  participants: Array<{
    id: string;
    name: string;
    contactId: string;
  }>;
  items: Item[];
  shares: ItemShare[];
}

export interface UserStats {
  name: string;
  email: string;
}

