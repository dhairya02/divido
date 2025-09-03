import { NextResponse } from "next/server";

export async function POST() {
  // Bulk deletion of contacts is disabled to preserve history
  return NextResponse.json({ error: "Bulk contact deletion is disabled." }, { status: 405 });
}

import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";

export async function POST(req: Request) {
  try {
    const { ids } = (await req.json()) as { ids: string[] };
    if (!Array.isArray(ids) || ids.length === 0) {
      return NextResponse.json({ error: "ids required" }, { status: 400 });
    }
    await prisma.billParticipant.deleteMany({ where: { contactId: { in: ids } } });
    const res = await prisma.contact.deleteMany({ where: { id: { in: ids } } });
    return NextResponse.json({ deleted: res.count });
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "Invalid request" }, { status: 400 });
  }
}


