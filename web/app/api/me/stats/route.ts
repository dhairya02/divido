import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ bills: 0, contacts: 0 }, { status: 200 });
  const userId = (session.user as any).id as string;
  const [bills, contacts, user] = await Promise.all([
    prisma.bill.count({ where: { userId } }),
    prisma.contact.count({ where: { userId, isTemporary: false } }),
    prisma.user.findUnique({ where: { id: userId }, select: { name: true, email: true } }),
  ]);
  return NextResponse.json({ bills, contacts, name: user?.name ?? undefined, email: user?.email ?? undefined });
}


