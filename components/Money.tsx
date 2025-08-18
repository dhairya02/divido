"use client";
import { formatCents } from "@/lib/currency";

export default function Money({ cents, currency = "USD" }: { cents: number; currency?: string }) {
  return <span>{formatCents(cents, currency)}</span>;
}


