import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";

export async function POST() {
  // Clear all bills and their dependent records
  const bills = await prisma.bill.findMany({ select: { id: true } });
  const billIds = bills.map((b) => b.id);
  if (billIds.length === 0) return NextResponse.json({ deleted: 0 });

  await prisma.itemShare.deleteMany({ where: { item: { billId: { in: billIds } } } });
  await prisma.item.deleteMany({ where: { billId: { in: billIds } } });
  await prisma.billParticipant.deleteMany({ where: { billId: { in: billIds } } });
  const res = await prisma.bill.deleteMany({ where: { id: { in: billIds } } });
  return NextResponse.json({ deleted: res.count });
}


