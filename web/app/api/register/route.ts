import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import bcrypt from "bcrypt";
import { z } from "zod";

export const runtime = "nodejs";

const schema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(8) });

export async function POST(req: Request) {
  try {
    const { name, email, password } = schema.parse(await req.json());
    const emailLower = email.toLowerCase().trim();
    const existing = await prisma.user.findUnique({ where: { email: emailLower } });
    if (existing) return NextResponse.json({ error: "Email already registered" }, { status: 400 });
    const passwordHash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({ data: { name, email: emailLower, passwordHash } });
    // Auto-create a corresponding Contact for this user (non-temporary)
    await prisma.contact.create({ data: { name: name || emailLower, email: emailLower, userId: user.id, isTemporary: false } });
    return NextResponse.json({ id: user.id });
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}


