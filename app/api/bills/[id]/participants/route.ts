import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";

type Params = { params: Promise<{ id: string }> };

export async function POST(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const body = (await req.json()) as { contactId: string; note?: string };
    if (!body?.contactId) throw new Error("contactId required");
    const created = await prisma.billParticipant.create({
      data: { billId: id, contactId: body.contactId, note: body.note },
    });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


