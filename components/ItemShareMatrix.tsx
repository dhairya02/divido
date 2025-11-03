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
      <div className="overflow-auto">
        <table className="w-full min-w-[600px] border text-sm">
          <thead>
            <tr className="bg-slate-100 dark:bg-slate-800">
              <th className="border px-3 py-2 text-left">Item</th>
              <th className="border px-3 py-2 text-right">Price</th>
              {participants.map((participant) => (
                <th key={participant.id} className="border px-3 py-2 text-center">
                  {participant.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {items.map((item, idx) => (
              <tr key={item.id} className={idx % 2 === 0 ? "bg-white dark:bg-slate-900/40" : "bg-slate-50 dark:bg-slate-900/20"}>
                <td className="border px-3 py-2 text-left align-top">
                  <div className="font-medium">{item.name}</div>
                </td>
                <td className="border px-3 py-2 text-right align-top">
                  <Money cents={item.priceCents} />
                </td>
                {participants.map((participant) => {
                  const current = weights[item.id]?.[participant.id] ?? 0;
                  const checked = current > 0;
                  return (
                    <td key={participant.id} className="border px-3 py-2 align-top">
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
            ))}
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


