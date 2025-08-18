"use client";
import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";
import ItemShareEditor from "@/components/ItemShareEditor";
import Money from "@/components/Money";
import ReceiptOCR from "@/components/ReceiptOCR";
import ConfirmDialog from "@/components/ConfirmDialog";
import AlertDialog from "@/components/AlertDialog";

type Participant = { id: string; name: string };
type Item = { id: string; name: string; priceCents: number };
type Share = { id: string; itemId: string; participantId: string; weight: number };

export default function BillDetailPage() {
  const params = useParams<{ id: string }>();
  const billId = params.id as unknown as string;
  const [bill, setBill] = useState<any>(null);
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [participantContactIds, setParticipantContactIds] = useState<string[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [shares, setShares] = useState<Share[]>([]);

  const [newItemName, setNewItemName] = useState("");
  const [newItemPrice, setNewItemPrice] = useState("0");
  const [newItemTaxable, setNewItemTaxable] = useState(true);
  const [newItemTaxRatePct, setNewItemTaxRatePct] = useState<number | "">("");
  const [adding, setAdding] = useState(false);
  const [addError, setAddError] = useState<string | null>(null);

  const load = async () => {
    const data = await fetch(`/api/bills/${billId}`).then((r) => r.json());
    setBill(data.bill);
    setParticipants(data.participants.map((p: any) => ({ id: p.id, name: p.name })));
    setParticipantContactIds(data.participants.map((p: any) => p.contactId));
    setItems(data.items);
    setShares(data.shares);
  };

  useEffect(() => {
    load();
  }, [billId]);

  const addItem = async (e: React.FormEvent) => {
    e.preventDefault();
    setAdding(true);
    setAddError(null);
    try {
      const parsed = parseFloat((newItemPrice || "0").toString().replace(/[^0-9.\-]/g, ""));
      const priceCents = Number.isFinite(parsed) ? Math.round(parsed * 100) : 0;
      const taxRatePct = newItemTaxable
        ? (newItemTaxRatePct === "" ? (bill?.taxRatePct ?? 0) : Number(newItemTaxRatePct))
        : 0;
      const res = await fetch(`/api/bills/${billId}/items`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: newItemName, priceCents, taxable: newItemTaxable, taxRatePct }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error || `Failed to add item (status ${res.status})`);
      setNewItemName("");
      setNewItemPrice("0");
      setNewItemTaxable(true);
      setNewItemTaxRatePct("");
      await load();
    } catch (err) {
      setAddError(err instanceof Error ? err.message : "Could not add item");
      console.error(err);
    } finally {
      setAdding(false);
    }
  };

  const updateItem = async (itemId: string, name: string, priceCents: number) => {
    await fetch(`/api/bills/${billId}/items`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ itemId, name, priceCents }),
    });
    await load();
  };

  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);
  const deleteItem = async (itemId: string) => {
    setPendingDeleteId(itemId);
  };
  const confirmDelete = async () => {
    if (!pendingDeleteId) return;
    await fetch(`/api/bills/${billId}/items`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ itemId: pendingDeleteId }),
    });
    setPendingDeleteId(null);
    await load();
  };

  const calc = async () => {
    const res = await fetch(`/api/bills/${billId}/calc`);
    const data = await res.json();
    if (data.error) {
      const fmt = (n: number) => new Intl.NumberFormat(undefined, { style: "currency", currency: bill?.currency || "USD" }).format(n / 100);
      const message = data.itemsTotalCents !== undefined && data.billSubtotalCents !== undefined
        ? `Items total (${fmt(data.itemsTotalCents)}) does not match bill subtotal (${fmt(data.billSubtotalCents)}).\nUpdate items or bill subtotal.`
        : String(data.error);
      setAlert({ open: true, message, title: "Cannot calculate" });
      return;
    }
    setCalcResult(data);
  };

  const [calcResult, setCalcResult] = useState<any | null>(null);
  const [alert, setAlert] = useState<{ open: boolean; title?: string; message?: string }>({ open: false });

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      {bill && (
        <div className="space-y-2">
          <h1 className="text-2xl font-semibold">{bill.title}</h1>
          <div className="text-sm text-gray-600">
            {bill.venue ? `${bill.venue} · ` : ""}Subtotal: <Money cents={bill.subtotalCents} /> · Tax {bill.taxRatePct}% · Tip {bill.tipRatePct}%
          </div>
        </div>
      )}

      <section className="space-y-3">
        <h2 className="text-xl font-semibold">Items</h2>
        <AddParticipants billId={billId} existingContactIds={participantContactIds} onAdded={load} />
        <ReceiptOCR
          onItems={async (items) => {
            for (const it of items) {
              const priceCents = Math.round(it.price * 100);
              await fetch(`/api/bills/${billId}/items`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ name: it.name, priceCents }),
              });
            }
            await load();
          }}
        />
        <form onSubmit={addItem} className="flex gap-2 items-center flex-wrap">
          <input className="input" placeholder="Item name" value={newItemName} onChange={(e) => setNewItemName(e.target.value)} required />
          <input className="input w-40" type="number" step="0.01" placeholder="Price (e.g., 12.34)" value={newItemPrice} onChange={(e) => setNewItemPrice(e.target.value)} />
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={newItemTaxable} onChange={(e) => setNewItemTaxable(e.target.checked)} /> Taxable
          </label>
          {newItemTaxable && (
            <label className="flex items-center gap-2 text-sm">
              <span>Tax %</span>
              <input className="input w-24" type="number" step="0.001" value={newItemTaxRatePct as any} onChange={(e) => setNewItemTaxRatePct(e.target.value === "" ? "" : Number(e.target.value))} />
            </label>
          )}
          <button className="btn-primary" type="submit" disabled={adding}>{adding ? "Adding..." : "Add"}</button>
          {addError && <span className="text-red-600 text-sm">{addError}</span>}
        </form>
        <div className="space-y-3">
          {items.map((it) => (
            <div key={it.id} className="space-y-2">
              <div className="flex justify-between items-center gap-3">
                <div className="flex items-center gap-2">
                  <input
                    className="input w-48"
                    defaultValue={it.name}
                    onBlur={(e) => updateItem(it.id, e.target.value, it.priceCents)}
                  />
                  <input
                    className="input w-28"
                    type="number"
                    step="0.01"
                    defaultValue={(it.priceCents / 100).toFixed(2)}
                    onBlur={(e) => updateItem(it.id, it.name, Math.round(parseFloat(e.target.value || "0") * 100))}
                  />
                  <label className="flex items-center gap-2 text-sm">
                    <input type="checkbox" defaultChecked={(it as any).taxable ?? true} onChange={async (e) => {
                      await fetch(`/api/bills/${billId}/items`, {
                        method: "PATCH",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ itemId: it.id, taxable: e.target.checked }),
                      });
                      await load();
                    }} />
                    Taxable
                  </label>
                  {(it as any).taxable !== false && (
                    <label className="flex items-center gap-2 text-sm">
                      <span>Tax %</span>
                      <input
                        className="input w-24"
                        type="number"
                        step="0.001"
                        defaultValue={(it as any).taxRatePct ?? ""}
                        onBlur={async (e) => {
                          const v = e.target.value;
                          await fetch(`/api/bills/${billId}/items`, {
                            method: "PATCH",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify({ itemId: it.id, taxRatePct: v === "" ? 0 : Number(v) }),
                          });
                          await load();
                        }}
                      />
                    </label>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <Money cents={it.priceCents} />
                  <button className="btn" onClick={() => deleteItem(it.id)} type="button">Delete</button>
                </div>
              </div>
              <ItemShareEditor
                itemId={it.id}
                participants={participants}
                existingShares={shares.filter((s) => s.itemId === it.id)}
                billId={billId}
              />
            </div>
          ))}
        </div>
      </section>

      <div>
        <button className="btn-primary" onClick={calc} type="button">Calculate split</button>
      </div>

      {calcResult && (
        <section className="space-y-2">
          <h2 className="text-xl font-semibold">Summary</h2>
          <div className="text-sm">Subtotal <Money cents={calcResult.billTotals.subtotalCents} /> · Tax <Money cents={calcResult.billTotals.taxCents} /> · Tip <Money cents={calcResult.billTotals.tipCents} /> · Total <Money cents={calcResult.billTotals.grandTotalCents} /></div>
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left border-b">
                <th className="py-2">Person</th>
                <th>Pre-tax</th>
                <th>Tax</th>
                <th>Tip</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {calcResult.participants.map((p: any) => (
                <tr key={p.participantId} className="border-b">
                  <td className="py-2">{p.name}</td>
                  <td><Money cents={p.preTaxCents} /></td>
                  <td><Money cents={p.taxCents} /></td>
                  <td><Money cents={p.tipCents} /></td>
                  <td><Money cents={p.totalOwedCents} /></td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Item-by-person matrix */}
          <h3 className="text-lg font-medium mt-4">By item</h3>
          <div className="overflow-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left border-b">
                  <th className="py-2">Item</th>
                  {participants.map((p) => (
                    <th key={p.id}>{p.name}</th>
                  ))}
                  <th className="text-right">Item total</th>
                </tr>
              </thead>
              <tbody>
                {items.map((it) => {
                  const row = calcResult.byItem.find((x: any) => x.itemId === it.id);
                  const total = row ? row.allocations.reduce((a: number, r: any) => a + r.cents, 0) : 0;
                  return (
                    <tr key={it.id} className="border-b">
                      <td className="py-2">{it.name}</td>
                      {participants.map((p) => {
                        const cents = row?.allocations.find((r: any) => r.participantId === p.id)?.cents ?? 0;
                        return (
                          <td key={p.id}><Money cents={cents} /></td>
                        );
                      })}
                      <td className="text-right"><Money cents={total} /></td>
                    </tr>
                  );
                })}
              </tbody>
              <tfoot>
                <tr className="font-medium">
                  <td>Total per person</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.preTaxCents ?? 0;
                    return <td key={p.id}><Money cents={val} /></td>;
                  })}
                  <td className="text-right"><Money cents={calcResult.billTotals.subtotalCents} /></td>
                </tr>
              </tfoot>
            </table>
          </div>
        </section>
      )}

      <ConfirmDialog
        open={pendingDeleteId !== null}
        title="Delete item"
        message="Are you sure you want to delete this item?"
        confirmText="Delete"
        cancelText="Cancel"
        onCancel={() => setPendingDeleteId(null)}
        onConfirm={confirmDelete}
      />
      <AlertDialog
        open={alert.open}
        title={alert.title}
        message={alert.message}
        onClose={() => setAlert({ open: false })}
      />
    </div>
  );
}

function AddParticipants({ billId, existingContactIds, onAdded }: { billId: string; existingContactIds: string[]; onAdded: () => Promise<void> | void }) {
  const [contacts, setContacts] = useState<{ id: string; name: string }[]>([]);
  useEffect(() => {
    fetch(`/api/contacts`).then((r) => r.json()).then((data) => setContacts(data));
  }, []);
  const add = async (contactId: string) => {
    await fetch(`/api/bills/${billId}/participants`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contactId }),
    });
    await onAdded();
  };
  const candidates = contacts.filter((c) => !existingContactIds.includes(c.id));
  if (candidates.length === 0) return null;
  return (
    <div className="space-y-2">
      <div className="text-sm text-gray-600">Add participants</div>
      <div className="flex flex-wrap gap-2">
        {candidates.map((c) => (
          <button key={c.id} className="chip" type="button" onClick={() => add(c.id)}>
            + {c.name}
          </button>
        ))}
      </div>
    </div>
  );
}


