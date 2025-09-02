import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { contactCreateSchema } from "@/lib/schemas";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json([]);
  const contacts = await prisma.contact.findMany({
    where: { userId: (session.user as any).id, isTemporary: false },
    orderBy: { name: "asc" },
  });
  return NextResponse.json(contacts);
}

export async function POST(req: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    const data = contactCreateSchema.parse(await req.json());
    const created = await prisma.contact.create({ data: { ...data, isTemporary: data.isTemporary ?? false, userId: (session.user as any).id } });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


