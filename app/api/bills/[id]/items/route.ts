import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { itemCreateSchema, itemUpdateSchema, shareUpsertSchema } from "@/lib/schemas";

type Params = { params: Promise<{ id: string }> };

export async function POST(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const data = itemCreateSchema.parse(await req.json());
    const created = await prisma.item.create({
      data: { ...data, billId: id },
    });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}

export async function PUT(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const data = shareUpsertSchema.parse(await req.json());
    // Verify the item belongs to the bill
    const item = await prisma.item.findUnique({ where: { id: data.itemId } });
    if (!item || item.billId !== id) throw new Error("Item not in bill");

    const upserted = await prisma.itemShare.upsert({
      where: { itemId_participantId: { itemId: data.itemId, participantId: data.participantId } },
      create: { ...data },
      update: { weight: data.weight },
    });
    return NextResponse.json(upserted);
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}

export async function PATCH(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const body = await req.json();
    const { itemId, ...updates } = body as { itemId: string } & Record<string, unknown>;
    if (!itemId) throw new Error("itemId required");
    const parsed = itemUpdateSchema.parse(updates);
    const item = await prisma.item.findUnique({ where: { id: itemId } });
    if (!item || item.billId !== id) throw new Error("Item not in bill");
    const updated = await prisma.item.update({ where: { id: itemId }, data: parsed });
    return NextResponse.json(updated);
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}

export async function DELETE(req: Request, { params }: Params) {
  const { id } = await params;
  try {
    const { itemId } = (await req.json()) as { itemId: string };
    if (!itemId) throw new Error("itemId required");
    const item = await prisma.item.findUnique({ where: { id: itemId } });
    if (!item || item.billId !== id) throw new Error("Item not in bill");
    await prisma.itemShare.deleteMany({ where: { itemId } });
    await prisma.item.delete({ where: { id: itemId } });
    return NextResponse.json({ ok: true });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


