"use client";
import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";

export default function BalanceDetailPage() {
  const params = useParams<{ contactId: string }>();
  const contactId = params.contactId as unknown as string;
  const [rows, setRows] = useState<{ billTitle: string; billId: string; payerId: string; payerName: string; cents: number }[]>([]);
  const [meId, setMeId] = useState<string | null>(null);
  const [personName, setPersonName] = useState<string>("");

  useEffect(() => {
    (async () => {
      const [bills, contacts, me] = await Promise.all([
        fetch("/api/bills", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/contacts", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/me/contact", { cache: "no-store" }).then((r) => r.json()).catch(() => null),
      ]);
      if (me && me.id) setMeId(me.id);
      const nameMap: Record<string, string> = {};
      for (const c of contacts) nameMap[c.id] = c.name;
      setPersonName(nameMap[contactId] || contactId);
      const out: { billTitle: string; billId: string; payerId: string; payerName: string; cents: number }[] = [];
      for (const b of bills as any[]) {
        const calc = await fetch(`/api/bills/${b.id}/calc`).then((r) => r.json());
        const payer = b.paidByContactId as string | undefined;
        if (!calc || !payer) continue;
        const mePart = (me?.id ? calc.participants.find((x: any) => x.contactId === me.id) : null);
        const selPart = calc.participants.find((x: any) => x.contactId === contactId);
        // Only include bills where the payer is either me or the selected contact
        if (payer === me?.id && selPart) {
          out.push({ billTitle: b.title, billId: b.id, payerId: payer, payerName: nameMap[payer] || payer, cents: selPart.totalOwedCents });
        } else if (payer === contactId && mePart) {
          out.push({ billTitle: b.title, billId: b.id, payerId: payer, payerName: nameMap[payer] || payer, cents: -mePart.totalOwedCents });
        }
      }
      setRows(out);
    })();
  }, [contactId]);

  const fmt = (cents: number) => new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(cents / 100);
  const totals = useMemo(() => rows.reduce((net, r) => net + r.cents, 0), [rows]);

  const signed = (cents: number) => `${cents >= 0 ? "+" : "-"}${fmt(Math.abs(cents))}`;

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-4">
      <h1 className="text-2xl font-semibold">{personName}</h1>
      <table className="w-full text-base border rounded">
        <thead>
          <tr className="border-b" style={{ backgroundColor: "var(--color-primary)", color: "#fff" }}>
            <th className="px-4 py-3 text-left">Bill</th>
            <th className="px-4 py-3 text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, idx) => (
            <tr key={r.billId} className="border-b" style={{ backgroundColor: idx % 2 === 0 ? "#f8fafc" : "#ffffff" }}>
              <td className="px-4 py-2"><Link className="underline" href={`/bills/${r.billId}`}>{r.billTitle}</Link></td>
              <td className="px-4 py-2 text-right">{signed(r.cents)}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan={2} className="px-4 py-6">No items.</td></tr>
          )}
        </tbody>
        <tfoot>
          <tr>
            <td className="px-4 py-2 font-semibold">Net</td>
            <td className="px-4 py-2 text-right font-semibold">{signed(totals)}</td>
          </tr>
        </tfoot>
      </table>
    </div>
  );
}


