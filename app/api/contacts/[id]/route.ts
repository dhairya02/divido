import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { contactUpdateSchema } from "@/lib/schemas";

type Params = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const body = await req.json();
    const updates = contactUpdateSchema.parse(body);
    const updated = await prisma.contact.update({ where: { id }, data: updates });
    return NextResponse.json(updated);
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}

export async function DELETE(_: Request, { params }: Params) {
  const { id } = await params;
  try {
    // Remove dependent participants
    await prisma.billParticipant.deleteMany({ where: { contactId: id } });
    await prisma.contact.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}


