import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { calculateSplit } from "@/lib/calc";

type Params = { params: Promise<{ id: string }> };

export async function GET(_: Request, { params }: Params) {
  const { id } = await params;
  const bill = await prisma.bill.findUnique({
    where: { id },
    include: {
      participants: { include: { contact: true } },
      items: true,
    },
  });
  if (!bill) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const shares = await prisma.itemShare.findMany({ where: { item: { billId: id } } });

  if (bill.items.length === 0) {
    return NextResponse.json({ error: "No items in bill." }, { status: 400 });
  }
  // Check that items sum matches the bill's declared subtotal
  const itemsTotal = bill.items.reduce((a, i) => a + i.priceCents, 0);
  if (itemsTotal !== bill.subtotalCents) {
    return NextResponse.json(
      {
        error: `Items total (${itemsTotal}) does not match bill subtotal (${bill.subtotalCents}). Update items or bill subtotal.`,
        itemsTotalCents: itemsTotal,
        billSubtotalCents: bill.subtotalCents,
      },
      { status: 400 }
    );
  }
  // Ensure every item has at least one share
  for (const item of bill.items) {
    const itemShares = shares.filter((s) => s.itemId === item.id && s.weight > 0);
    if (itemShares.length === 0) {
      return NextResponse.json({ error: `Item "${item.name}" has no shares.` }, { status: 400 });
    }
  }

  const result = calculateSplit({
    items: bill.items.map((i) => ({ id: i.id, priceCents: i.priceCents, taxable: i.taxable, taxRatePct: i.taxRatePct })),
    participants: bill.participants.map((bp) => ({ id: bp.id, name: bp.contact.name })),
    shares: shares.map((s) => ({ itemId: s.itemId, participantId: s.participantId, weight: s.weight })),
    taxRatePct: bill.taxRatePct,
    tipRatePct: bill.tipRatePct,
    taxMode: bill.taxMode,
  });

  return NextResponse.json(result);
}


