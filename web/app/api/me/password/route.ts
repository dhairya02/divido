import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";
import bcrypt from "bcrypt";

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const userId = (session.user as any).id as string;
  const { current, next } = await req.json().catch(() => ({}));
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.passwordHash) return NextResponse.json({ error: "No password set" }, { status: 400 });
  const ok = await bcrypt.compare(current || "", user.passwordHash);
  if (!ok) return NextResponse.json({ error: "Current password incorrect" }, { status: 400 });
  const hash = await bcrypt.hash(String(next || ""), 12);
  await prisma.user.update({ where: { id: userId }, data: { passwordHash: hash } });
  return NextResponse.json({ ok: true });
}


