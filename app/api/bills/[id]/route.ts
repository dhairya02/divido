import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

type Params = { params: Promise<{ id: string }> };

export async function GET(_: Request, { params }: Params) {
  const { id } = await params;
  const bill = await prisma.bill.findUnique({
    where: { id },
    include: {
      participants: {
        include: { contact: true },
      },
      items: true,
    },
  });
  if (!bill) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const shares = await prisma.itemShare.findMany({
    where: { item: { billId: id } },
  });

  return NextResponse.json({
    bill,
    participants: bill.participants.map((bp) => ({ id: bp.id, name: bp.contact.name, contactId: bp.contactId })),
    items: bill.items,
    shares,
  });
}

export async function DELETE(_: Request, { params }: Params) {
  const { id } = await params;
  await prisma.itemShare.deleteMany({ where: { item: { billId: id } } });
  await prisma.item.deleteMany({ where: { billId: id } });
  await prisma.billParticipant.deleteMany({ where: { billId: id } });
  await prisma.bill.delete({ where: { id } });
  return NextResponse.json({ ok: true });
}

export async function PATCH(req: Request, { params }: Params) {
  const { id } = await params;
  const body = await req.json().catch(() => ({}));
  const { paidByContactId, subtotalCents, taxRatePct, tipRatePct } = body as {
    paidByContactId?: string;
    subtotalCents?: number;
    taxRatePct?: number;
    tipRatePct?: number;
  };

  if (
    paidByContactId === undefined &&
    subtotalCents === undefined &&
    taxRatePct === undefined &&
    tipRatePct === undefined
  ) {
    return NextResponse.json({ error: "No updatable fields provided" }, { status: 400 });
  }

  const data: { paidByContactId?: string; subtotalCents?: number; taxRatePct?: number; tipRatePct?: number } = {};
  if (paidByContactId !== undefined) data.paidByContactId = paidByContactId;
  if (typeof subtotalCents === "number" && Number.isInteger(subtotalCents) && subtotalCents >= 0) {
    data.subtotalCents = subtotalCents;
  }
  if (typeof taxRatePct === "number" && Number.isFinite(taxRatePct) && taxRatePct >= 0) {
    data.taxRatePct = taxRatePct;
  }
  if (typeof tipRatePct === "number" && Number.isFinite(tipRatePct) && tipRatePct >= 0) {
    data.tipRatePct = tipRatePct;
  }

  await prisma.bill.update({ where: { id }, data });
  return NextResponse.json({ ok: true });
}


