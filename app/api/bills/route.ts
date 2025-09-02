import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { billCreateSchema } from "@/lib/schemas";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export async function GET() {
  const session = await getServerSession(authOptions);
  const where = session ? { userId: (session.user as any)?.id } : {};
  const bills = await prisma.bill.findMany({
    where: where as any,
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      title: true,
      venue: true,
      date: true,
      subtotalCents: true,
      taxRatePct: true,
      tipRatePct: true,
      convenienceFeeRatePct: true,
      currency: true,
    },
  });
  return NextResponse.json(bills);
}

export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    const data = billCreateSchema.parse(await req.json());
    const { participantContactIds = [], ...billData } = data;
    const created = await prisma.bill.create({
      data: {
        ...billData,
        userId: (session.user as any).id,
        participants: {
          create: participantContactIds.map((contactId) => ({ contactId })),
        },
      },
      select: { id: true },
    });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


