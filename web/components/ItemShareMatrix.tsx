"use client";

import { useEffect, useMemo, useState } from "react";
import Money from "./Money";

type Participant = { id: string; name: string };
type Item = { id: string; name: string; priceCents: number };
type Share = { itemId: string; participantId: string; weight: number };

type Matrix = Record<string, Record<string, number>>;

function buildMatrix(items: Item[], participants: Participant[], shares: Share[]): Matrix {
  const matrix: Matrix = {};
  for (const item of items) {
    matrix[item.id] = {};
    for (const participant of participants) {
      matrix[item.id][participant.id] = 0;
    }
  }
  for (const share of shares) {
    if (matrix[share.itemId]) {
      matrix[share.itemId][share.participantId] = share.weight;
    }
  }
  return matrix;
}

type SortOrder = "asc" | "desc" | null;

export default function ItemShareMatrix({
  items,
  participants,
  shares,
  billId,
  onSaved,
}: {
  items: Item[];
  participants: Participant[];
  shares: Share[];
  billId: string;
  onSaved?: () => Promise<void> | void;
}) {
  const initialMatrix = useMemo(() => buildMatrix(items, participants, shares), [items, participants, shares]);
  const [weights, setWeights] = useState<Matrix>(initialMatrix);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hoverRow, setHoverRow] = useState<string | null>(null);
  const [hoverCol, setHoverCol] = useState<string | null>(null);
  const [focusCell, setFocusCell] = useState<{ row: string; col: string } | null>(null);
  const [itemSortOrder, setItemSortOrder] = useState<SortOrder>(null);
  const [editingItemId, setEditingItemId] = useState<string | null>(null);
  const [editingItemName, setEditingItemName] = useState("");
  const [savingItemName, setSavingItemName] = useState(false);

  const sortedItems = useMemo(() => {
    if (!itemSortOrder) return items;
    return [...items].sort((a, b) => {
      const cmp = a.name.localeCompare(b.name);
      return itemSortOrder === "asc" ? cmp : -cmp;
    });
  }, [items, itemSortOrder]);

  const toggleItemSort = () => {
    setItemSortOrder((prev) => {
      if (prev === null) return "asc";
      if (prev === "asc") return "desc";
      return null;
    });
  };

  const startEditingItem = (item: Item) => {
    setEditingItemId(item.id);
    setEditingItemName(item.name);
  };

  const cancelEditingItem = () => {
    setEditingItemId(null);
    setEditingItemName("");
  };

  const saveItemName = async (itemId: string) => {
    const trimmedName = editingItemName.trim();
    const originalItem = items.find((i) => i.id === itemId);
    if (!trimmedName || trimmedName === originalItem?.name) {
      cancelEditingItem();
      return;
    }

    setSavingItemName(true);
    setError(null);
    try {
      const res = await fetch(`/api/bills/${billId}/items`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ itemId, name: trimmedName }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({} as any));
        throw new Error(data?.error || `Failed to update item name (${res.status})`);
      }
      await onSaved?.();
      cancelEditingItem();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save item name");
    } finally {
      setSavingItemName(false);
    }
  };

  const handleItemNameKeyDown = (e: React.KeyboardEvent, itemId: string) => {
    if (e.key === "Enter") {
      e.preventDefault();
      saveItemName(itemId);
    } else if (e.key === "Escape") {
      cancelEditingItem();
    }
  };

  useEffect(() => {
    setWeights(initialMatrix);
  }, [initialMatrix]);

  const setWeight = (itemId: string, participantId: string, weight: number) => {
    setWeights((prev) => ({
      ...prev,
      [itemId]: {
        ...prev[itemId],
        [participantId]: weight,
      },
    }));
  };

  const isDirty = useMemo(() => {
    for (const item of items) {
      for (const participant of participants) {
        const next = weights[item.id]?.[participant.id] ?? 0;
        const prev = initialMatrix[item.id]?.[participant.id] ?? 0;
        if (Math.abs(next - prev) > Number.EPSILON) return true;
      }
    }
    return false;
  }, [weights, initialMatrix, items, participants]);

  const save = async () => {
    const changes: { itemId: string; participantId: string; weight: number }[] = [];
    for (const item of items) {
      for (const participant of participants) {
        const next = weights[item.id]?.[participant.id] ?? 0;
        const prev = initialMatrix[item.id]?.[participant.id] ?? 0;
        if (Math.abs(next - prev) > Number.EPSILON) {
          changes.push({ itemId: item.id, participantId: participant.id, weight: next });
        }
      }
    }

    if (changes.length === 0) return;

    setSaving(true);
    setError(null);
    try {
      await Promise.all(
        changes.map(async ({ itemId, participantId, weight }) => {
          const res = await fetch(`/api/bills/${billId}/items`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ itemId, participantId, weight }),
          });
          if (!res.ok) {
            const data = await res.json().catch(() => ({} as any));
            throw new Error(data?.error || `Failed to update share (${res.status})`);
          }
        })
      );
      await onSaved?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save shares");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-3">
      <div className="overflow-auto max-h-[70vh]">
        <table className="w-full min-w-[600px] border text-sm">
          <thead>
            <tr className="bg-slate-100 dark:bg-slate-800">
              <th
                className="border px-3 py-2 text-left sticky left-0 top-0 z-30 bg-slate-100 dark:bg-slate-800 cursor-pointer select-none hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
                onClick={toggleItemSort}
                title="Click to sort by item name"
              >
                <span className="flex items-center gap-1">
                  Item
                  <span className="text-xs text-slate-400">
                    {itemSortOrder === "asc" && "▲"}
                    {itemSortOrder === "desc" && "▼"}
                    {itemSortOrder === null && "⇅"}
                  </span>
                </span>
              </th>
              <th
                className={`border px-3 py-2 text-right sticky top-0 z-20 bg-slate-100 dark:bg-slate-800 ${hoverCol === "__price" ? "bg-indigo-100 dark:bg-indigo-900" : ""}`}
                onMouseEnter={() => setHoverCol("__price")}
                onMouseLeave={() => setHoverCol(null)}
              >
                Price
              </th>
              {participants.map((participant) => (
                <th
                  key={participant.id}
                  className={`border px-3 py-2 text-center sticky top-0 z-20 bg-slate-100 dark:bg-slate-800 ${hoverCol === participant.id ? "bg-indigo-100 dark:bg-indigo-900" : ""}`}
                  onMouseEnter={() => setHoverCol(participant.id)}
                  onMouseLeave={() => setHoverCol(null)}
                >
                  {participant.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {sortedItems.map((item, idx) => {
              const rowBgClass = idx % 2 === 0 ? "bg-white dark:bg-slate-900/40" : "bg-slate-50 dark:bg-slate-900/20";
              const rowHover = hoverRow === item.id;
              const priceFocused = focusCell?.row === item.id && focusCell?.col === "__price";
              return (
                <tr
                  key={item.id}
                  className={`${rowBgClass} ${rowHover ? "bg-indigo-50/70 dark:bg-indigo-900/40" : ""}`}
                  onMouseEnter={() => setHoverRow(item.id)}
                  onMouseLeave={() => setHoverRow(null)}
                >
                  <td
                    className={`border px-3 py-2 text-left align-top sticky left-0 z-20 ${rowBgClass} ${rowHover ? "bg-indigo-50/70 dark:bg-indigo-900/40" : ""}`}
                  >
                    {editingItemId === item.id ? (
                      <input
                        type="text"
                        value={editingItemName}
                        onChange={(e) => setEditingItemName(e.target.value)}
                        onBlur={() => saveItemName(item.id)}
                        onKeyDown={(e) => handleItemNameKeyDown(e, item.id)}
                        className="input w-full font-medium"
                        autoFocus
                        disabled={savingItemName}
                      />
                    ) : (
                      <div
                        className="font-medium cursor-pointer hover:text-indigo-600 dark:hover:text-indigo-400 transition-colors"
                        onClick={() => startEditingItem(item)}
                        title="Click to edit item name"
                      >
                        {item.name}
                      </div>
                    )}
                  </td>
                  <td
                    className={`border px-3 py-2 text-right align-top ${hoverCol === "__price" || rowHover ? "bg-indigo-50/70 dark:bg-indigo-900/40" : ""} ${priceFocused ? "ring-2 ring-indigo-500 font-semibold" : ""}`}
                    onMouseEnter={() => {
                      setHoverCol("__price");
                      setFocusCell({ row: item.id, col: "__price" });
                    }}
                    onMouseLeave={() => {
                      if (hoverCol === "__price") setHoverCol(null);
                      setFocusCell(null);
                    }}
                  >
                    <Money cents={item.priceCents} />
                  </td>
                {participants.map((participant) => {
                  const current = weights[item.id]?.[participant.id] ?? 0;
                  const checked = current > 0;
                  const active = hoverCol === participant.id || rowHover;
                  const focused = focusCell?.row === item.id && focusCell?.col === participant.id;
                  return (
                    <td
                      key={participant.id}
                      className={`border px-3 py-2 align-top ${rowBgClass} ${active ? "bg-indigo-50/70 dark:bg-indigo-900/40" : ""} ${focused ? "ring-2 ring-indigo-500 font-semibold" : ""}`}
                      onMouseEnter={() => {
                        setHoverCol(participant.id);
                        setFocusCell({ row: item.id, col: participant.id });
                      }}
                      onMouseLeave={() => {
                        setFocusCell(null);
                      }}
                    >
                      <label className="flex flex-col items-start gap-1 text-xs">
                        <span className="flex items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={checked}
                            onChange={(e) => setWeight(item.id, participant.id, e.target.checked ? current || 1 : 0)}
                          />
                          <span>Include</span>
                        </span>
                        <input
                          type="number"
                          min={0}
                          step={0.1}
                          value={checked ? current : 1}
                          onChange={(e) => setWeight(item.id, participant.id, Number(e.target.value))}
                          className="input w-20"
                          disabled={!checked}
                        />
                        <span className="text-[10px] uppercase tracking-wide text-slate-500">Multiplier</span>
                      </label>
                    </td>
                  );
                })}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <div className="flex items-center gap-3">
        <button className="btn-primary" type="button" onClick={save} disabled={!isDirty || saving}>
          {saving ? "Saving..." : "Save changes"}
        </button>
        {!isDirty && !saving && <span className="text-sm text-slate-500">No unsaved changes</span>}
        {error && <span className="text-sm text-red-600">{error}</span>}
      </div>
    </div>
  );
}


