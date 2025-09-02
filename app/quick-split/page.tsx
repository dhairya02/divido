"use client";
import { useEffect, useMemo, useState } from "react";

type Contact = { id: string; name: string };

export default function QuickSplitPage() {
  const [title, setTitle] = useState("Quick Split");
  const [venue, setVenue] = useState("");
  const [totalDollars, setTotalDollars] = useState("0");
  const [feePct, setFeePct] = useState<number>(0);
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [tempName, setTempName] = useState("");
  const [paidBy, setPaidBy] = useState<string>("");
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/contacts")
      .then((r) => r.json())
      .then((data) => setContacts(data.map((c: any) => ({ id: c.id, name: c.name }))));
  }, []);

  const participants = useMemo(() => contacts.filter((c) => selected[c.id]), [contacts, selected]);

  const addTemp = () => {
    const name = tempName.trim();
    if (!name) return;
    const id = `temp-${crypto.randomUUID()}`;
    setContacts((prev) => [...prev, { id, name }]);
    setSelected((s) => ({ ...s, [id]: true }));
    setTempName("");
  };

  const split = useMemo(() => {
    const total = Math.round(parseFloat((totalDollars || "0").replace(/[^0-9.\-]/g, "")) * 100) || 0;
    const fee = Math.round((total * (feePct || 0)) / 100);
    const grand = total + fee;
    const n = participants.length || 1;
    const base = Math.floor(grand / n);
    const remainder = grand - base * n;
    return participants.map((p, idx) => ({ id: p.id, name: p.name, cents: base + (idx < remainder ? 1 : 0) }));
  }, [participants, totalDollars, feePct]);

  const save = async () => {
    try {
      setSaving(true);
      setErrorMsg(null);
      if (participants.length === 0) {
        setErrorMsg("Select at least one participant.");
        return;
      }
      // Ensure contacts exist for temp participants
      const ensuredIds: string[] = [];
      const tempToReal: Record<string, string> = {};
      for (const p of participants) {
        if (p.id.startsWith("temp-")) {
          const res = await fetch("/api/contacts", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: p.name, isTemporary: true }) });
          const data = await res.json();
          if (res.status === 401) { setErrorMsg("Please log in to save a bill."); return; }
          if (!res.ok || !data?.id) throw new Error(data?.error || "Failed to create contact");
          ensuredIds.push(data.id);
          tempToReal[p.id] = data.id as string;
        } else {
          ensuredIds.push(p.id);
        }
      }
      const subtotalCents = Math.round(parseFloat((totalDollars || "0").replace(/[^0-9.\-]/g, "")) * 100) || 0;
      const paidByResolved = paidBy ? (paidBy.startsWith("temp-") ? (tempToReal[paidBy] || undefined) : paidBy) : undefined;
      const billRes = await fetch("/api/bills", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ title: title || "Quick Split", venue, subtotalCents, taxRatePct: 0, tipRatePct: 0, convenienceFeeRatePct: feePct || 0, participantContactIds: ensuredIds, paidByContactId: paidByResolved, taxMode: "GLOBAL" }) });
      const billData = await billRes.json();
      if (billRes.status === 401) { setErrorMsg("Please log in to save a bill."); return; }
      if (!billRes.ok || !billData?.id) throw new Error(billData?.error || "Failed to create bill");
      const billId = billData.id as string;
      // Create a synthetic item equal to subtotal
      const itemRes = await fetch(`/api/bills/${billId}/items`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: "Quick Split Total", priceCents: subtotalCents, quantity: 1 }) });
      const itemData = await itemRes.json();
      if (itemRes.status === 401) { setErrorMsg("Please log in to save a bill."); return; }
      if (!itemRes.ok || !itemData?.id) throw new Error(itemData?.error || "Failed to add item");
      const itemId = itemData.id as string;
      // Fetch bill participants to get BillParticipant ids
      const billFull = await fetch(`/api/bills/${billId}`).then((r) => r.json());
      const bps: { id: string; name: string }[] = billFull.participants || [];
      // Set equal weights (1) for each participant on the single item
      await Promise.all(bps.map((bp) => fetch(`/api/bills/${billId}/items`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ itemId, participantId: bp.id, weight: 1 }) })));
      // Redirect to calculate view
      window.location.href = `/bills/${billId}?calc=1`;
    } catch (e) {
      setErrorMsg(e instanceof Error ? e.message : "Could not save");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Quick Split (equal)</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Title</span>
          <input className="input" placeholder="Quick Split" value={title} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Venue (optional)</span>
          <input className="input" placeholder="" value={venue} onChange={(e) => setVenue(e.target.value)} />
        </label>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Total (USD)</span>
          <div className="flex items-center gap-2">
            <span className="px-2 py-2 rounded border border-black/10 dark:border-white/15">$</span>
            <input className="input flex-1" placeholder="100.00" type="number" step="0.01" min="0" value={totalDollars} onChange={(e) => setTotalDollars(e.target.value)} />
          </div>
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Convenience fee % (optional)</span>
          <div className="flex items-center gap-2">
            <input className="input flex-1" placeholder="0" type="number" step="0.1" min="0" value={feePct} onChange={(e) => setFeePct(Number(e.target.value))} />
            <span className="px-2">%</span>
          </div>
        </label>
      </div>

      <div className="space-y-2">
        <div className="text-sm text-gray-600">Participants</div>
        <div className="flex flex-wrap gap-2 border rounded p-2 max-h-40 overflow-auto">
          {contacts.map((c) => (
            <button
              key={c.id}
              type="button"
              className={`chip ${selected[c.id] ? "chip-selected" : ""}`}
              onClick={() => setSelected((s) => ({ ...s, [c.id]: !s[c.id] }))}
            >
              {selected[c.id] ? "✓ " : "+ "}{c.name}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2">
          <input className="input" placeholder="Add temporary name" value={tempName} onChange={(e) => setTempName(e.target.value)} />
          <button className="btn" type="button" onClick={addTemp}>Add temp</button>
        </div>
      </div>

      <div>
        <div className="text-sm text-gray-600 mb-2">Who paid?</div>
        <select className="input w-full max-w-sm" value={paidBy} onChange={(e) => setPaidBy(e.target.value)}>
          <option value="">Select payer (optional)</option>
          {participants.map((p) => (
            <option key={p.id} value={p.id}>{p.name}</option>
          ))}
        </select>
      </div>

      <section className="space-y-2">
        <h2 className="text-lg font-medium">Result</h2>
        {errorMsg && <div className="text-red-600 text-sm">{errorMsg}</div>}
        {participants.length === 0 ? (
          <div className="text-sm text-gray-500">Select at least one participant.</div>
        ) : (
          <table className="w-full text-sm border rounded">
            <thead>
              <tr className="border-b" style={{ backgroundColor: "var(--color-primary)", color: "#fff" }}>
                <th className="px-4 py-2 text-left">Name</th>
                <th className="px-4 py-2 text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {split.map((row) => (
                <tr key={row.id} className="border-b">
                  <td className="px-4 py-2">{row.name}</td>
                  <td className="px-4 py-2 text-right">{new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(row.cents / 100)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <div>
          <button className="btn-primary" onClick={save} disabled={saving || participants.length === 0}>{saving ? "Saving..." : "Save & Calculate"}</button>
        </div>
      </section>
    </div>
  );
}


