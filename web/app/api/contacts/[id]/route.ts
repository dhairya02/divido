import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { contactUpdateSchema } from "@/lib/schemas";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

type Params = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const body = await req.json();
    const updates = contactUpdateSchema.parse(body);
    const updated = await prisma.contact.update({ where: { id }, data: updates });
    // If this contact belongs to a user and has the user's email, keep User in sync
    if (updated.userId && updated.email) {
      const session = await getServerSession(authOptions);
      const currentUserId = (session?.user as any)?.id as string | undefined;
      // Only allow syncing the logged-in user's own profile
      if (!currentUserId || currentUserId !== updated.userId) {
        return NextResponse.json(updated);
      }
      await prisma.user.updateMany({ where: { id: updated.userId, email: updated.email }, data: { name: updated.name } });
    }
    return NextResponse.json(updated);
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}

export async function DELETE(_: Request, { params }: Params) {
  const { id } = await params;
  try {
    const session = await getServerSession(authOptions);
    if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    const userId = (session.user as any)?.id as string | undefined;
    const email = (session.user as any)?.email as string | undefined;
    if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

    const contact = await prisma.contact.findUnique({ where: { id } });
    if (!contact) return NextResponse.json({ error: "Not found" }, { status: 404 });
    if (contact.userId !== userId) return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    // Prevent deleting the self-contact linked to the account
    if (email && contact.email === email) {
      return NextResponse.json({ error: "You cannot delete your own profile contact." }, { status: 400 });
    }

    await prisma.$transaction(async (tx) => {
      // Remove dependent item shares for this contact's participants first
      const participants = await tx.billParticipant.findMany({ where: { contactId: id }, select: { id: true } });
      const participantIds = participants.map((p) => p.id);
      if (participantIds.length > 0) {
        await tx.itemShare.deleteMany({ where: { participantId: { in: participantIds } } });
      }
      // Then remove participants
      await tx.billParticipant.deleteMany({ where: { contactId: id } });
      // Clear payee references from bills
      await tx.bill.updateMany({ where: { paidByContactId: id }, data: { paidByContactId: null } });
      // Finally delete contact
      await tx.contact.delete({ where: { id } });
    });
    return NextResponse.json({ ok: true });
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}


