import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/db";

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json(null, { status: 200 });
  const userId = (session.user as any)?.id as string | undefined;
  const email = (session.user as any)?.email as string | undefined;
  const name = (session.user as any)?.name as string | undefined;
  if (!userId) return NextResponse.json(null, { status: 200 });

  // Search within the current user's contacts for a record that represents the user.
  // Prefer email match, then name match.
  const byEmail = email
    ? await prisma.contact.findFirst({ where: { userId, email } })
    : null;
  const contact = byEmail ?? (name ? await prisma.contact.findFirst({ where: { userId, name } }) : null);

  return NextResponse.json(contact ? { id: contact.id, name: contact.name } : null);
}


