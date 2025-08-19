import Link from "next/link";
import { prisma } from "@/lib/db";
import Money from "@/components/Money";
import { revalidatePath } from "next/cache";
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
      <form action={async (formData: FormData) => {
        "use server";
        const ids = formData.getAll('billId') as string[];
        if (ids.length) {
          await prisma.itemShare.deleteMany({ where: { item: { billId: { in: ids } } } });
          await prisma.item.deleteMany({ where: { billId: { in: ids } } });
          await prisma.billParticipant.deleteMany({ where: { billId: { in: ids } } });
          await prisma.bill.deleteMany({ where: { id: { in: ids } } });
          revalidatePath('/bills');
        }
      }} className="space-y-2">
        <div className="space-y-2">
          {bills.map((b) => (
            <label key={b.id} className="flex items-center justify-between border rounded p-3 hover:bg-black/5 dark:hover:bg-white/10">
              <div className="flex items-center gap-3">
                <input type="checkbox" name="billId" value={b.id} />
                <Link href={`/bills/${b.id}?calc=1`} className="font-medium hover:underline">{b.title}</Link>
                <div className="text-xs text-gray-500">{b.venue ?? ""} {new Date(b.createdAt).toLocaleString()}</div>
              </div>
              <Money cents={b.subtotalCents} currency={b.currency} />
            </label>
          ))}
        </div>
        {bills.length > 0 && (
          <div>
            <button className="btn" type="submit">Delete selected bills</button>
          </div>
        )}
      </form>
    </div>
  );
}


