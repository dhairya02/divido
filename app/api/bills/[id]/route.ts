import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";

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
  const { paidByContactId } = body as { paidByContactId?: string };
  if (!paidByContactId) return NextResponse.json({ error: "paidByContactId required" }, { status: 400 });
  await prisma.bill.update({ where: { id }, data: { paidByContactId } });
  return NextResponse.json({ ok: true });
}


