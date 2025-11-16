"use client";
/**
 * Bill detail page
 * - Add items (name, price, qty, taxability/rate)
 * - Per-item share editor with click-to-select participants and adjustable weights
 * - Calculate split and present per-person table + item matrix with summary footers
 */
import { useEffect, useMemo, useRef, useState } from "react";
import { useParams } from "next/navigation";
import ItemShareEditor from "@/components/ItemShareEditor";
import ItemShareMatrix from "@/components/ItemShareMatrix";
import Money from "@/components/Money";
import ReceiptOCR from "@/components/ReceiptOCR";
import ConfirmDialog from "@/components/ConfirmDialog";
import AlertDialog from "@/components/AlertDialog";
import html2canvas from "html2canvas";

type Participant = { id: string; name: string; contactId?: string };
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
  const [shareViewMode, setShareViewMode] = useState<"cards" | "table">("cards");

  const [newItemName, setNewItemName] = useState("");
  const [newItemPrice, setNewItemPrice] = useState("0");
  const [newItemTaxable, setNewItemTaxable] = useState(true);
  const [newItemTaxRatePct, setNewItemTaxRatePct] = useState<number | "">("");
  const [newItemQty, setNewItemQty] = useState<number>(1);
  const [adding, setAdding] = useState(false);
  const [addError, setAddError] = useState<string | null>(null);
  const [savedItems, setSavedItems] = useState<Record<string, boolean>>({});
  const [headerEdit, setHeaderEdit] = useState(false);
  const [headerSaved, setHeaderSaved] = useState(false);

  const load = async () => {
    const data = await fetch(`/api/bills/${billId}`).then((r) => r.json());
    setBill(data.bill);
    setParticipants(data.participants.map((p: any) => ({ id: p.id, name: p.name, contactId: p.contactId })));
    setParticipantContactIds(data.participants.map((p: any) => p.contactId));
    setItems((data.items as Item[]).slice().reverse());
    setShares(data.shares);
  };

  useEffect(() => {
    load();
    const q = new URLSearchParams(window.location.search);
    if (q.get('calc') === '1') {
      setTimeout(() => { void calc(); }, 0);
    }
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
        body: JSON.stringify({ name: newItemName, priceCents, taxable: newItemTaxable, taxRatePct, quantity: newItemQty }),
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
  const exportRef = useRef<HTMLDivElement | null>(null);
  const [exporting, setExporting] = useState(false);
  const exportPNG = async () => {
    if (!exportRef.current) return;
    try {
      setExporting(true);
      // Get the actual width of the content
      const scrollWidth = exportRef.current.scrollWidth;
      const scrollHeight = exportRef.current.scrollHeight;
      
      const canvas = await html2canvas(exportRef.current, { 
        backgroundColor: "#ffffff", 
        scale: 2,
        windowWidth: scrollWidth,
        windowHeight: scrollHeight,
        width: scrollWidth,
        height: scrollHeight,
        scrollX: 0,
        scrollY: 0,
        useCORS: true,
      });
      const link = document.createElement("a");
      link.download = `${bill?.title || "bill"}-by-item.png`;
      link.href = canvas.toDataURL("image/png");
      link.click();
    } catch (err) {
      setAlert({ open: true, title: "Export failed", message: err instanceof Error ? err.message : String(err) });
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="w-full p-6 space-y-6">
      {bill && (
        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-semibold">{bill.title}</h1>
            {/* Payee pill */}
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-600">Payee:</span>
              <div className="flex items-center gap-2">
                <select
                  className="chip"
                  value={bill.paidByContactId || ""}
                  onChange={async (e) => {
                    const val = e.target.value || null;
                    await fetch(`/api/bills/${billId}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ paidByContactId: val }) });
                    await load();
                  }}
                >
                  <option value="">?</option>
                  {participants.map((p) => (
                    <option key={p.id} value={p.contactId || p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>
          <div className="text-sm text-gray-600 flex items-center gap-3 flex-wrap">
            <span>{bill.venue ? `${bill.venue} · ` : ""}</span>
            <button
              className="btn text-xs"
              onClick={() => setHeaderEdit((prev) => !prev)}
              type="button"
            >{headerEdit ? "Done" : "Edit"}</button>
            {!headerEdit && (
              <>
                <span>Subtotal: <Money cents={bill.subtotalCents} /> · Tax {bill.taxRatePct}% · Tip {bill.tipRatePct}%</span>
                {headerSaved && <span className="text-emerald-600">Saved</span>}
              </>
            )}
            {headerEdit && (
              <form
                onSubmit={async (e) => {
                  e.preventDefault();
                  const form = e.currentTarget as HTMLFormElement;
                  const sub = form.elements.namedItem("subtotal") as HTMLInputElement;
                  const tax = form.elements.namedItem("tax") as HTMLInputElement;
                  const tip = form.elements.namedItem("tip") as HTMLInputElement;
                  const parsed = parseFloat((sub.value || "0").replace(/[^0-9.\-]/g, ""));
                  const cents = Number.isFinite(parsed) ? Math.round(parsed * 100) : 0;
                  const taxNum = Number(tax.value || 0);
                  const tipNum = Number(tip.value || 0);
                  await fetch(`/api/bills/${billId}`, {
                    method: "PATCH",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ subtotalCents: cents, taxRatePct: taxNum, tipRatePct: tipNum }),
                  });
                  setHeaderSaved(true);
                  setTimeout(() => setHeaderSaved(false), 1500);
                  await load();
                }}
                className="flex items-center gap-2"
              >
                <label className="flex items-center gap-1">
                  <span>Subtotal</span>
                  <input name="subtotal" className="input w-24" defaultValue={(bill.subtotalCents / 100).toFixed(2)} type="text" />
                </label>
                <label className="flex items-center gap-1">
                  <span>Tax %</span>
                  <input name="tax" className="input w-16" defaultValue={String(bill.taxRatePct)} type="number" step="0.001" />
                </label>
                <label className="flex items-center gap-1">
                  <span>Tip %</span>
                  <input name="tip" className="input w-16" defaultValue={String(bill.tipRatePct)} type="number" step="0.1" />
                </label>
                <button className="btn text-xs" type="submit">Save</button>
                {headerSaved && <span className="text-emerald-600">Saved</span>}
              </form>
            )}
          </div>
        </div>
      )}
      <hr className="border-t border-black/10 dark:border-white/10" />
      <section className="space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-xl font-semibold">Items</h2>
          <div className="flex items-center gap-2 text-sm">
            <span className="text-gray-600">Share view</span>
            <div className="flex gap-2">
              <button
                className={shareViewMode === "cards" ? "btn-primary text-xs" : "btn text-xs"}
                type="button"
                onClick={() => setShareViewMode("cards")}
              >
                Per item
              </button>
              <button
                className={shareViewMode === "table" ? "btn-primary text-xs" : "btn text-xs"}
                type="button"
                onClick={() => setShareViewMode("table")}
              >
                Table
              </button>
            </div>
          </div>
        </div>
        <hr className="border-t border-black/10 dark:border-white/10" />
        {/* Removed duplicate payer selection; payee lives in header */}
        <form onSubmit={addItem} className="flex gap-2 items-center flex-wrap">
          <input className="input" placeholder="Item name" value={newItemName} onChange={(e) => setNewItemName(e.target.value)} required />
          <input className="input w-40" type="number" step="0.01" placeholder="Price (e.g., 12.34)" value={newItemPrice} onChange={(e) => setNewItemPrice(e.target.value)} />
          <label className="flex items-center gap-2 text-sm">
            <span>Qty</span>
            <input className="input w-20" type="number" min={1} value={newItemQty} onChange={(e) => setNewItemQty(Number(e.target.value))} />
          </label>
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
        <hr className="border-t border-black/10 dark:border-white/10" />
        <ReceiptOCR
          onItems={async (items) => {
            // Batch add parsed items sequentially; ignore failures per-line but surface a summary
            const failures: string[] = [];
            for (const it of items) {
              const priceCents = Math.round(it.price * 100);
              try {
                const res = await fetch(`/api/bills/${billId}/items`, {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({ name: it.name, priceCents, taxable: true, quantity: 1 }),
                });
                if (!res.ok) {
                  const data = await res.json().catch(() => ({} as any));
                  failures.push(`${it.name}: ${data?.error || res.status}`);
                }
              } catch (err) {
                failures.push(`${it.name}: network error`);
              }
            }
            await load();
            if (failures.length > 0) {
              setAlert({ open: true, title: "Some items could not be added", message: failures.join("\n") });
            }
          }}
        />
        <hr className="border-t border-black/10 dark:border-white/10" />
        <AddParticipants billId={billId} existingContactIds={participantContactIds} onAdded={load} />
        <hr className="border-t border-black/10 dark:border-white/10" />
        {shareViewMode === "cards" ? (
          <div className="space-y-3 max-h-[70vh] overflow-auto pr-2">
            {items.map((it) => (
              <div
                key={it.id}
                className={`space-y-2 rounded border border-black/20 dark:border-white/20 p-3 ${savedItems[it.id] ? "bg-black/[.04] dark:bg-white/[.06]" : ""}`}
              >
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
                      <span>Qty</span>
                      <input
                        className="input w-20"
                        type="number"
                        min={1}
                        defaultValue={(it as any).quantity ?? 1}
                        onBlur={async (e) => {
                          await fetch(`/api/bills/${billId}/items`, {
                            method: "PATCH",
                            headers: { "Content-Type": "application/json" },
                            body: JSON.stringify({ itemId: it.id, quantity: Number(e.target.value) }),
                          });
                          await load();
                        }}
                      />
                    </label>
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
                <div className="border-t border-dashed border-black/20 dark:border-white/20 my-2" />
                <div className="rounded border border-black/15 dark:border-white/15 p-2 bg-black/[.01] dark:bg-white/[.02]">
                  <ItemShareEditor
                    itemId={it.id}
                    participants={participants}
                    existingShares={shares.filter((s) => s.itemId === it.id)}
                    billId={billId}
                    onSaved={() => setSavedItems((s) => ({ ...s, [it.id]: true }))}
                  />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <ItemShareMatrix items={items} participants={participants} shares={shares} billId={billId} onSaved={load} />
        )}
      </section>
      <hr className="border-t border-black/10 dark:border-white/10" />
      <div>
        <button className="btn-primary" onClick={calc} type="button">Calculate split</button>
      </div>
      <hr className="border-t border-black/10 dark:border-white/10" />
      {calcResult && (
        <section className="space-y-2">
          <h2 className="text-xl font-semibold">Summary</h2>
          {/* Export composition wrapper: logo + title/venue + table */}
          <div className="overflow-x-auto">
            <div className="space-y-3 p-4 rounded border inline-block min-w-full" ref={exportRef} style={{ backgroundColor: "#ffffff", color: "#111827", borderColor: "#e5e7eb" }}>
              <div className="flex items-center gap-3">
                <img src="/restaurantsplit-high-resolution-logo.png" alt="Divido" className="h-8 w-8 object-contain" />
                <div className="text-xl font-semibold" style={{ color: "#111827" }}>{bill?.title || "Bill"}</div>
              </div>
              <div className="text-sm whitespace-nowrap" style={{ color: "#374151" }}>
                {bill?.venue ? `${bill.venue} · ` : ""}
                {bill?.paidByContactId ? `Payee ${participants.find((p) => p.contactId === bill.paidByContactId)?.name || ""} · ` : ""}
                Subtotal <Money cents={calcResult.billTotals.subtotalCents} /> · Tax <Money cents={calcResult.billTotals.taxCents} /> · Tip <Money cents={calcResult.billTotals.tipCents} /> · Conv. fee <Money cents={calcResult.billTotals.convenienceFeeCents} /> · Total <Money cents={calcResult.billTotals.grandTotalCents} />
              </div>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "16px", border: "1px solid #e5e7eb" }}>
              <thead>
                <tr style={{ backgroundColor: "#6f8bff", color: "#ffffff" }}>
                  <th style={{ padding: "12px", textAlign: "left", border: "1px solid #e5e7eb" }}>Item</th>
                  {participants.map((p) => (
                    <th key={p.id} style={{ padding: "12px", textAlign: "right", border: "1px solid #e5e7eb" }}>{p.name}</th>
                  ))}
                  <th style={{ padding: "12px", textAlign: "right", border: "1px solid #e5e7eb" }}>Item total</th>
                </tr>
              </thead>
              <tbody>
                {items.map((it, idx) => {
                  const row = calcResult.byItem.find((x: any) => x.itemId === it.id);
                  const total = row ? row.allocations.reduce((a: number, r: any) => a + r.cents, 0) : 0;
                  return (
                    <tr key={it.id} style={{ backgroundColor: idx % 2 === 0 ? "#f8fafc" : "#ffffff" }}>
                      <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>{it.name}</td>
                      {participants.map((p) => {
                        const cents = row?.allocations.find((r: any) => r.participantId === p.id)?.cents ?? 0;
                        return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}>{cents === 0 ? "-" : <Money cents={cents} />}</td>;
                      })}
                      <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}>{total === 0 ? "-" : <Money cents={total} />}</td>
                    </tr>
                  );
                })}
              </tbody>
              <tfoot>
                <tr style={{ backgroundColor: "#e8ffa3", fontWeight: 500 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Subtotal per person</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.preTaxCents ?? 0;
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.subtotalCents} /></td>
                </tr>
                <tr style={{ fontWeight: 500 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Tax</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.taxCents ?? 0;
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.taxCents} /></td>
                </tr>
                <tr style={{ backgroundColor: "#b794d9", fontWeight: 500 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Total with tax</td>
                  {participants.map((p) => {
                    const part = calcResult.participants.find((x: any) => x.participantId === p.id);
                    const val = (part?.preTaxCents ?? 0) + (part?.taxCents ?? 0);
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.subtotalCents + calcResult.billTotals.taxCents} /></td>
                </tr>
                <tr style={{ fontWeight: 500 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Tip</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.tipCents ?? 0;
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.tipCents} /></td>
                </tr>
                <tr style={{ fontWeight: 500 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Convenience fee</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.convenienceFeeCents ?? 0;
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.convenienceFeeCents} /></td>
                </tr>
                <tr style={{ backgroundColor: "#6f8bff", color: "#ffffff", fontWeight: 600 }}>
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "left" }}>Total with tip</td>
                  {participants.map((p) => {
                    const val = calcResult.participants.find((x: any) => x.participantId === p.id)?.totalOwedCents ?? 0;
                    return <td key={p.id} style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={val} /></td>;
                  })}
                  <td style={{ padding: "8px", border: "1px solid #e5e7eb", textAlign: "right" }}><Money cents={calcResult.billTotals.grandTotalCents} /></td>
                </tr>
              </tfoot>
            </table>
            </div>
          </div>
          <div>
            <button className="btn" type="button" onClick={exportPNG} disabled={exporting}>{exporting ? "Exporting..." : "Export table as PNG"}</button>
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


