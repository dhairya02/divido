import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";

export async function PATCH(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const userId = (session.user as any).id as string;
  const { name } = await req.json().catch(() => ({}));
  // Update user profile
  const user = await prisma.user.update({ where: { id: userId }, data: { name } });
  // Keep the user's self-contact in sync (identified by matching email)
  if (user?.email) {
    await prisma.contact.updateMany({ where: { userId, email: user.email }, data: { name } });
  }
  return NextResponse.json({ ok: true });
}


