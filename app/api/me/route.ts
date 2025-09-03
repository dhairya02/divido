import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";

export async function DELETE() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const userId = (session.user as any)?.id as string | undefined;
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  try {
    // Collect IDs for cascading cleanup
    const [bills, contacts] = await Promise.all([
      prisma.bill.findMany({ where: { userId }, select: { id: true } }),
      prisma.contact.findMany({ where: { userId }, select: { id: true } }),
    ]);
    const billIds = bills.map((b) => b.id);
    const contactIds = contacts.map((c) => c.id);

    // Remove participation and items for user's bills and contacts
    if (billIds.length > 0) {
      await prisma.itemShare.deleteMany({ where: { item: { billId: { in: billIds } } } as any });
      await prisma.item.deleteMany({ where: { billId: { in: billIds } } });
      await prisma.billParticipant.deleteMany({ where: { billId: { in: billIds } } });
    }
    if (contactIds.length > 0) {
      await prisma.billParticipant.deleteMany({ where: { contactId: { in: contactIds } } });
      await prisma.bill.updateMany({ where: { paidByContactId: { in: contactIds } }, data: { paidByContactId: null } });
    }

    // Delete the user's data
    await prisma.bill.deleteMany({ where: { id: { in: billIds } } });
    await prisma.contact.deleteMany({ where: { id: { in: contactIds } } });

    // Delete the user (accounts/sessions use onDelete: Cascade)
    await prisma.user.delete({ where: { id: userId } });

    return NextResponse.json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : "Failed to delete account";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}


