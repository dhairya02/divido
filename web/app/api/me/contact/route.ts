import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";
import { contactUpdateSchema } from "@/lib/schemas";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json(null, { status: 200 });
  const userId = (session.user as any)?.id as string | undefined;
  const email = (session.user as any)?.email as string | undefined;
  const name = (session.user as any)?.name as string | undefined;
  if (!userId) return NextResponse.json(null, { status: 200 });

  // Search within the current user's contacts for a record that represents the user.
  // Prefer email match, then name match.
  const byEmail = email ? await prisma.contact.findFirst({ where: { userId, email } }) : null;
  const contact = byEmail ?? (name ? await prisma.contact.findFirst({ where: { userId, name } }) : null);

  return NextResponse.json(
    contact
      ? { id: contact.id, name: contact.name, email: contact.email, phone: contact.phone, venmo: contact.venmo, cashapp: contact.cashapp }
      : null
  );
}

export async function PATCH(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  const userId = (session.user as any)?.id as string | undefined;
  const email = (session.user as any)?.email as string | undefined;
  const name = (session.user as any)?.name as string | undefined;
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const updates = contactUpdateSchema.parse(await req.json());
  // Locate or create the self-contact
  let contact = email
    ? await prisma.contact.findFirst({ where: { userId, email } })
    : null;
  if (!contact) {
    contact = await prisma.contact.findFirst({ where: { userId, name: name || undefined } });
  }
  if (!contact) {
    // Create a new self-contact if missing
    contact = await prisma.contact.create({ data: { userId, name: name || email || "Me", email: email || undefined, isTemporary: false } });
  }
  const saved = await prisma.contact.update({ where: { id: contact.id }, data: updates });
  return NextResponse.json(saved);
}


