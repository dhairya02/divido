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
    const userId = (session.user as any)?.id as string | undefined;
    if (!userId) return NextResponse.json({ error: "Session invalid. Please sign in again." }, { status: 401 });
    // Validate that the user exists to avoid FK violations when DB was reset
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return NextResponse.json({ error: "Session expired. Please log in again." }, { status: 401 });

    const data = contactCreateSchema.parse(await req.json());
    // Prevent duplicate self-contact by email
    if (data.email) {
      const existing = await prisma.contact.findFirst({ where: { userId, email: data.email } });
      if (existing) return NextResponse.json(existing, { status: 200 });
    }
    const created = await prisma.contact.create({ data: { ...data, isTemporary: data.isTemporary ?? false, userId } });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


