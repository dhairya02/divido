"use client";
import { useEffect, useState } from "react";
import ParticipantPicker from "@/components/ParticipantPicker";
import { useSession } from "next-auth/react";

type Contact = { id: string; name: string };

export default function NewBillPage() {
  const { data: session } = useSession();
  const [title, setTitle] = useState("");
  const [venue, setVenue] = useState("");
  const [subtotalDollars, setSubtotalDollars] = useState("0");
  const [taxRatePct, setTaxRatePct] = useState(8.875);
  const [tipRatePct, setTipRatePct] = useState(15);
  const [feeRatePct, setFeeRatePct] = useState(0);
  const [taxMode, setTaxMode] = useState<"GLOBAL" | "ITEM">("GLOBAL");
  const [selected, setSelected] = useState<string[]>([]);
  const [paidBy, setPaidBy] = useState<string>("");
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [contactsCache, setContactsCache] = useState<any[]>([]);

  useEffect(() => {
    fetch("/api/contacts").then((r) => r.json()).then((data) => setContactsCache(data));
  }, []);

  const toggle = (id: string) => {
    setSelected((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]));
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setErrorMsg(null);
    try {
      const parsed = parseFloat((subtotalDollars || "0").toString().replace(/[^0-9.\-]/g, ""));
      const subtotalCents = Number.isFinite(parsed) ? Math.round(parsed * 100) : 0;
      const res = await fetch("/api/bills", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ title, venue, subtotalCents, taxRatePct, tipRatePct, participantContactIds: selected, taxMode, convenienceFeeRatePct: feeRatePct, paidByContactId: paidBy || undefined }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error || `Failed to create bill (status ${res.status})`);
      if (data?.id) {
        location.href = `/bills/${data.id}`;
      } else {
        // guest mode: persist to sessionStorage and navigate to a local bill view
        const bill = { id: `guest-${Date.now()}`, title, venue, subtotalCents, taxRatePct, tipRatePct, taxMode, participants: selected };
        sessionStorage.setItem("guestBill", JSON.stringify(bill));
        location.href = `/bills/${bill.id}`;
      }
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Something went wrong");
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">New Bill</h1>
        <a className="btn" href="/quick-split">Quick Split</a>
      </div>
      <form onSubmit={submit} className="space-y-3">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Title</span>
            <input className="input" placeholder="Dinner at Luigi's" value={title} onChange={(e) => setTitle(e.target.value)} required />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Convenience fee (%)</span>
            <div className="flex items-center gap-2">
              <input className="input flex-1" placeholder="0" type="number" step="0.1" min="0" value={feeRatePct} onChange={(e) => setFeeRatePct(Number(e.target.value))} />
              <span className="px-2">%</span>
            </div>
            <span className="text-xs text-gray-500">Optional surcharge distributed proportionally.</span>
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Venue (optional)</span>
            <input className="input" placeholder="Luigi's" value={venue} onChange={(e) => setVenue(e.target.value)} />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Subtotal (USD)</span>
            <div className="flex items-center gap-2">
              <span className="px-2 py-2 rounded border border-black/10 dark:border-white/15">$</span>
              <input className="input flex-1" placeholder="46.50" type="number" step="0.01" min="0" value={subtotalDollars} onChange={(e) => setSubtotalDollars(e.target.value)} />
            </div>
            <span className="text-xs text-gray-500">Enter the pre-tax subtotal for all items in dollars.</span>
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Tax rate (%)</span>
            <div className="flex items-center gap-2">
              <input className="input flex-1" placeholder="8.875" type="number" step="0.001" min="0" value={taxRatePct} onChange={(e) => setTaxRatePct(Number(e.target.value))} />
              <span className="px-2">%</span>
            </div>
            <span className="text-xs text-gray-500">Local sales tax percentage. We’ll allocate tax proportionally.</span>
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Tip rate (%)</span>
            <div className="flex items-center gap-2">
              <input className="input flex-1" placeholder="18" type="number" step="0.1" min="0" value={tipRatePct} onChange={(e) => setTipRatePct(Number(e.target.value))} />
              <span className="px-2">%</span>
            </div>
            <span className="text-xs text-gray-500">Tip percentage based on subtotal. Rounding is deterministic.</span>
          </label>
        </div>
        <div>
          <div className="text-sm text-gray-600 mb-2">Participants</div>
          <ParticipantPicker selectedIds={selected} onToggle={toggle} />
        </div>
        <div>
          <div className="text-sm text-gray-600 mb-2">Who paid?</div>
          <select className="input w-full max-w-sm" value={paidBy} onChange={(e) => setPaidBy(e.target.value)}>
            <option value="">Select payer (optional)</option>
            {selected.map((id) => {
              const c = (contactsCache.find?.((x: any) => x.id === id) as any) || { name: id };
              return <option key={id} value={id}>{c.name || id}</option>;
            })}
          </select>
        </div>
        <div className="flex items-center gap-4">
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="taxmode" checked={taxMode === "GLOBAL"} onChange={() => setTaxMode("GLOBAL")} /> Global tax
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="taxmode" checked={taxMode === "ITEM"} onChange={() => setTaxMode("ITEM")} /> Item-level tax
          </label>
        </div>
        {errorMsg && <div className="text-red-600 text-sm">{errorMsg}</div>}
        <button className="btn-primary" type="submit" disabled={submitting}>{submitting ? "Creating..." : "Create Bill"}</button>
      </form>
    </div>
  );
}


