"use client";
import { useEffect, useState } from "react";
import Link from "next/link";

type SimpleBill = { id: string; title: string; venue: string | null };

type Owes = Record<string, number>; // key `${from}->${to}` cents

export default function BalancesPage() {
  const [rows, setRows] = useState<{ contactId: string; name: string; cents: number }[]>([]);
  const [contacts, setContacts] = useState<Record<string, string>>({});
  const [bills, setBills] = useState<SimpleBill[]>([]);
  const [currentContactId, setCurrentContactId] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const [billsData, contactsData, me, stats] = await Promise.all([
        fetch("/api/bills", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/contacts", { cache: "no-store" }).then((r) => r.json()),
        fetch("/api/me/contact", { cache: "no-store" }).then((r) => r.json()).catch(() => null),
        fetch("/api/me/stats", { cache: "no-store" }).then((r) => r.json()).catch(() => null),
      ]);
      setBills(billsData);
      const nameMap: Record<string, string> = {};
      for (const c of contactsData) nameMap[c.id] = c.name;
      setContacts(nameMap);
      // Pick the contact matching the logged-in user's name/email if present
      // Resolve current user contact id, first from /api/me/contact, then fallback by name match
      let meId: string | null = null;
      if (me && me.id) meId = me.id as string;
      if (!meId && stats?.name) {
        const byName = (contactsData as any[]).find((c) => c.name === stats.name);
        if (byName) meId = byName.id as string;
      }
      if (meId) setCurrentContactId(meId);

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
      // If we know current user, collapse to net per counterparty relative to me
      if (meId) {
        const netByCounterparty: Record<string, number> = {};
        for (const [pair, cents] of Object.entries(owes)) {
          const [from, to] = pair.split("->");
          if (from === meId) {
            // I owe payer
            netByCounterparty[to] = (netByCounterparty[to] || 0) - cents;
          } else if (to === meId) {
            // They owe me
            netByCounterparty[from] = (netByCounterparty[from] || 0) + cents;
          }
        }
        const result = Object.entries(netByCounterparty)
          .filter(([, cents]) => cents !== 0)
          .map(([contactId, cents]) => ({ contactId, name: nameMap[contactId] || contactId, cents }))
          .sort((a, b) => Math.abs(b.cents) - Math.abs(a.cents));
        setRows(result);
      } else {
        // Fallback: show full from->to table collapsed by pair (no user filter)
        const byPair = Object.entries(owes)
          .map(([k, cents]) => {
            const [from, to] = k.split("->");
            return { contactId: `${from}->${to}`, name: `${nameMap[from] || from} → ${nameMap[to] || to}` , cents };
          })
          .filter((x) => x.cents > 0)
          .sort((a, b) => b.cents - a.cents);
        setRows(byPair);
      }
    })();
  }, []);

  const fmt = (cents: number) => new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(cents / 100);

  // Positive cents means they owe me; negative means I owe them
  const renderAmount = (cents: number) => `${cents >= 0 ? "+" : "-"}${fmt(Math.abs(cents))}`;

  return (
    <div className="w-full p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Balances</h1>
      <table className="w-full text-base border rounded">
        <thead>
          <tr className="border-b" style={{ backgroundColor: "var(--color-primary)", color: "#fff" }}>
            <th className="px-4 py-3 text-left">Person</th>
            <th className="px-4 py-3 text-right">Net</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.contactId} className="border-b">
              <td className="px-4 py-2">
                <Link className="underline" href={`/balances/${r.contactId}`}>{r.name}</Link>
              </td>
              <td className="px-4 py-2 text-right">{renderAmount(r.cents)}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td className="px-4 py-6" colSpan={2}>No balances yet.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}


