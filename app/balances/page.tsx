"use client";
import { useEffect, useState } from "react";
import Link from "next/link";

type SimpleBill = { id: string; title: string; venue: string | null };

type Owes = Record<string, number>; // key `${from}->${to}` cents

export default function BalancesPage() {
  const [rows, setRows] = useState<{ from: string; to: string; cents: number }[]>([]);
  const [contacts, setContacts] = useState<Record<string, string>>({});
  const [bills, setBills] = useState<SimpleBill[]>([]);
  const [currentContactId, setCurrentContactId] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const [billsData, contactsData, me] = await Promise.all([
        fetch("/api/bills", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/contacts", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/me/contact", { cache: "no-store" }).then((r) => r.json()).catch(() => null),
      ]);
      setBills(billsData);
      const nameMap: Record<string, string> = {};
      for (const c of contactsData) nameMap[c.id] = c.name;
      setContacts(nameMap);
      // Pick the contact matching the logged-in user's name/email if present
      if (me && me.id) setCurrentContactId(me.id);

      // naive aggregation using calc API for each bill
      const owes: Owes = {};
      for (const b of billsData as any[]) {
        const calc = await fetch(`/api/bills/${b.id}/calc`).then((r) => r.json());
        const payer = (b as any).paidByContactId as string | undefined;
        if (!calc || !calc.participants || !payer) continue;
        for (const p of calc.participants) {
          const contactId = (p as any).contactId || p.participantId; // fallback
          if (contactId === payer) continue;
          const key = `${contactId}->${payer}`;
          owes[key] = (owes[key] || 0) + p.totalOwedCents;
        }
      }
      let list = Object.entries(owes)
        .map(([k, cents]) => {
          const [from, to] = k.split("->");
          return { from, to, cents };
        })
        .filter((x) => x.cents > 0)
        .sort((a, b) => b.cents - a.cents);
      // If we know the current user's contact, filter to only what they owe or are owed
      if (currentContactId) {
        list = list.filter((r) => r.from === currentContactId || r.to === currentContactId);
      }
      setRows(list);
    })();
  }, []);

  const fmt = (cents: number) => new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(cents / 100);

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Balances</h1>
      <table className="w-full text-base border rounded">
        <thead>
          <tr className="border-b" style={{ backgroundColor: "var(--color-primary)", color: "#fff" }}>
            <th className="px-4 py-3 text-left">From</th>
            <th className="px-4 py-3 text-left">To</th>
            <th className="px-4 py-3 text-right">Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={`${r.from}-${r.to}`} className="border-b">
              <td className="px-4 py-2">
                <Link className="underline" href={`/balances/${r.from}`}>{contacts[r.from] || r.from}</Link>
              </td>
              <td className="px-4 py-2">{contacts[r.to] || r.to}</td>
              <td className="px-4 py-2 text-right">{fmt(r.cents)}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td className="px-4 py-6" colSpan={3}>No balances yet.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}


