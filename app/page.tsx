import Link from "next/link";
import Money from "@/components/Money";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function Home() {
  const session = await getServerSession(authOptions);
  if (!session) redirect("/login");
  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Divido</h1>
        <nav className="flex gap-2">
          <Link href="/bills" className="btn">Bills</Link>
          <Link href="/contacts" className="btn">Contacts</Link>
          <Link href="/bills/new" className="btn-primary">New Bill</Link>
        </nav>
      </header>
      <section className="space-y-2">
        <h2 className="text-lg font-medium">Quick start</h2>
        <ol className="list-decimal list-inside text-sm space-y-1">
          <li>Add your friends in Contacts</li>
          <li>Create a new bill with subtotal, tax, and tip</li>
          <li>Add items and assign shares by weight</li>
          <li>Calculate split and share totals</li>
        </ol>
      </section>
      <RecentBills />
    </div>
  );
}

async function RecentBills() {
  const { prisma } = await import("@/lib/db");
  const { getServerSession } = await import("next-auth");
  const { authOptions } = await import("@/lib/auth");
  const session = await getServerSession(authOptions);
  const bills = await prisma.bill.findMany({
    orderBy: { createdAt: "desc" },
    take: 5,
    where: session ? { userId: (session.user as any).id } : { id: "__none__" } as any,
    select: { id: true, title: true, subtotalCents: true, currency: true },
  });
  if (bills.length === 0) return null;
  return (
    <section className="space-y-2">
      <h2 className="text-lg font-medium">Recent bills</h2>
      <div className="grid gap-2">
        {bills.map((b) => (
          <Link key={b.id} href={`/bills/${b.id}`} className="flex justify-between items-center border rounded p-3 hover:bg-black/5 dark:hover:bg-white/10">
            <span>{b.title}</span>
            <Money cents={b.subtotalCents} currency={b.currency} />
          </Link>
        ))}
      </div>
    </section>
  );
}
