import Link from "next/link";
import { prisma } from "@/lib/db";
import Money from "@/components/Money";
import { revalidatePath } from "next/cache";

export const dynamic = "force-dynamic";

export default async function BillsHistoryPage() {
  const bills = await prisma.bill.findMany({
    orderBy: { createdAt: "desc" },
    select: {
      id: true,
      title: true,
      venue: true,
      createdAt: true,
      subtotalCents: true,
      currency: true,
    },
  });

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Bills</h1>
      <form action={async () => {
        "use server";
        await prisma.itemShare.deleteMany({});
        await prisma.item.deleteMany({});
        await prisma.billParticipant.deleteMany({});
        await prisma.bill.deleteMany({});
        revalidatePath("/bills");
        revalidatePath("/");
      }}>
        <button className="btn" type="submit">Clear all bills</button>
      </form>
      {bills.length === 0 ? (
        <div className="text-sm text-gray-500">No bills yet.</div>
      ) : (
        <div className="space-y-2">
          {bills.map((b) => (
            <Link key={b.id} href={`/bills/${b.id}`} className="flex justify-between items-center border rounded p-3 hover:bg-black/5 dark:hover:bg-white/10">
              <div>
                <div className="font-medium">{b.title}</div>
                <div className="text-xs text-gray-500">{b.venue ?? ""} {new Date(b.createdAt).toLocaleString()}</div>
              </div>
              <Money cents={b.subtotalCents} currency={b.currency} />
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}


