import { z } from "zod";

export const contactCreateSchema = z.object({
  name: z.string().min(1),
  email: z.string().email().optional().or(z.literal("")).transform((v) => (v ? v : undefined)),
  phone: z.string().optional().or(z.literal("")).transform((v) => (v ? v : undefined)),
  venmo: z.string().optional().or(z.literal("")).transform((v) => (v ? v : undefined)),
  cashapp: z.string().optional().or(z.literal("")).transform((v) => (v ? v : undefined)),
});

export const billCreateSchema = z.object({
  title: z.string().min(1),
  venue: z.string().optional().or(z.literal("")).transform((v) => (v ? v : undefined)),
  subtotalCents: z.number().int(),
  taxRatePct: z.number().nonnegative(),
  tipRatePct: z.number().nonnegative(),
  currency: z.string().default("USD").optional(),
  taxMode: z.enum(["GLOBAL", "ITEM"]).default("GLOBAL").optional(),
  participantContactIds: z.array(z.string()).optional(),
});

export const itemCreateSchema = z.object({
  name: z.string().min(1),
  priceCents: z.number().int(),
  quantity: z.number().int().min(1).default(1).optional(),
  taxable: z.boolean().optional(),
  taxRatePct: z.number().min(0).default(0).optional(),
});

export const itemUpdateSchema = z.object({
  name: z.string().min(1).optional(),
  priceCents: z.number().int().optional(),
  taxable: z.boolean().optional(),
  taxRatePct: z.number().min(0).optional(),
});

export const shareUpsertSchema = z.object({
  itemId: z.string(),
  participantId: z.string(),
  weight: z.number().min(0),
});

export type ContactCreateInput = z.infer<typeof contactCreateSchema>;
export type BillCreateInput = z.infer<typeof billCreateSchema>;
export type ItemCreateInput = z.infer<typeof itemCreateSchema>;
export type ItemUpdateInput = z.infer<typeof itemUpdateSchema>;
export type ShareUpsertInput = z.infer<typeof shareUpsertSchema>;


