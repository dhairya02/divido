import { NextResponse } from "next/server";
import { prisma } from "@/lib/db";
import { contactCreateSchema } from "@/lib/schemas";

export async function GET() {
  const contacts = await prisma.contact.findMany({
    orderBy: { name: "asc" },
  });
  return NextResponse.json(contacts);
}

export async function POST(req: Request) {
  try {
    const data = contactCreateSchema.parse(await req.json());
    const created = await prisma.contact.create({ data });
    return NextResponse.json(created, { status: 201 });
  } catch (err: unknown) {
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Invalid request" },
      { status: 400 }
    );
  }
}


