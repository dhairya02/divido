"use client";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";

export default function BalanceDetailPage() {
  const params = useParams<{ contactId: string }>();
  const contactId = params.contactId as unknown as string;
  const [rows, setRows] = useState<{ billTitle: string; billId: string; payerName: string; cents: number }[]>([]);

  useEffect(() => {
    (async () => {
      const [bills, contacts] = await Promise.all([
        fetch("/api/bills").then((r) => r.json()),
        fetch("/api/contacts").then((r) => r.json()),
      ]);
      const nameMap: Record<string, string> = {};
      for (const c of contacts) nameMap[c.id] = c.name;
      const out: { billTitle: string; billId: string; payerName: string; cents: number }[] = [];
      for (const b of bills as any[]) {
        const calc = await fetch(`/api/bills/${b.id}/calc`).then((r) => r.json());
        const payer = b.paidByContactId as string | undefined;
        if (!calc || !payer) continue;
        const p = calc.participants.find((x: any) => x.contactId === contactId);
        if (!p || p.contactId === payer) continue;
        out.push({ billTitle: b.title, billId: b.id, payerName: nameMap[payer] || payer, cents: p.totalOwedCents });
      }
      setRows(out);
    })();
  }, [contactId]);

  const fmt = (cents: number) => new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(cents / 100);
  const total = rows.reduce((a, r) => a + r.cents, 0);

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Balances detail</h1>
      <table className="w-full text-base border rounded">
        <thead>
          <tr className="border-b" style={{ backgroundColor: "var(--color-primary)", color: "#fff" }}>
            <th className="px-4 py-3 text-left">Bill</th>
            <th className="px-4 py-3 text-left">Paid to</th>
            <th className="px-4 py-3 text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.billId} className="border-b">
              <td className="px-4 py-2">{r.billTitle}</td>
              <td className="px-4 py-2">{r.payerName}</td>
              <td className="px-4 py-2 text-right">{fmt(r.cents)}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan={3} className="px-4 py-6">No items.</td></tr>
          )}
        </tbody>
        <tfoot>
          <tr>
            <td className="px-4 py-2 font-semibold">Total</td>
            <td />
            <td className="px-4 py-2 text-right font-semibold">{fmt(total)}</td>
          </tr>
        </tfoot>
      </table>
    </div>
  );
}


