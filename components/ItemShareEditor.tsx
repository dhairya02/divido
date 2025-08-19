"use client";
/**
 * ItemShareEditor
 *
 * UX model:
 * - Each participant renders as an unselected pill (chip). Clicking the chip selects the
 *   participant with a default weight of 1 and reveals a numeric weight input next to the name.
 * - Selected participant name is highlighted using the brand color and bold text. Clicking the
 *   highlighted name unselects it (sets weight to 0) while keeping the UI responsive.
 * - "Split equally" sets all current participants' weights to 1. "Save" persists weights to the server.
 */
import { useState } from "react";

type Participant = { id: string; name: string };
type Share = { itemId: string; participantId: string; weight: number };

export default function ItemShareEditor({
  itemId,
  participants,
  existingShares,
  billId,
}: {
  itemId: string;
  participants: Participant[];
  existingShares: Share[];
  billId: string;
}) {
  const initial: Record<string, number> = {};
  for (const p of participants) {
    const found = existingShares.find((s) => s.participantId === p.id);
    initial[p.id] = found?.weight ?? 0;
  }
  const [weights, setWeights] = useState<Record<string, number>>(initial);
  const setWeight = (pid: string, v: number) => {
    setWeights((w) => ({ ...w, [pid]: v }));
  };

  const splitEqually = () => {
    const next: Record<string, number> = {};
    for (const p of participants) next[p.id] = 1;
    setWeights(next);
  };

  const save = async () => {
    await Promise.all(
      Object.entries(weights).map(([participantId, weight]) =>
        fetch(`/api/bills/${billId}/items`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ itemId, participantId, weight }),
        })
      )
    );
  };

  return (
    <div className="flex flex-col gap-2 border rounded p-3">
      <div className="flex gap-3 flex-wrap items-center">
        {participants.map((p) => {
          const selected = (weights[p.id] ?? 0) > 0;
          if (!selected) {
            return (
              <button
                key={p.id}
                type="button"
                className="chip"
                onClick={() => setWeight(p.id, 1)}
                aria-pressed="false"
              >
                + {p.name}
              </button>
            );
          }
          return (
            <div key={p.id} className="flex items-center gap-2">
              <button
                type="button"
                className="px-3 py-1 rounded-full font-semibold text-black"
                style={{ backgroundColor: "var(--color-primary)" }}
                onClick={() => setWeight(p.id, 0)}
                aria-pressed="true"
                title="Remove participant from this item"
              >
                ✓ {p.name}
              </button>
              <input
                type="number"
                min={0}
                step={0.5}
                value={weights[p.id] ?? 0}
                onChange={(e) => setWeight(p.id, Number(e.target.value))}
                className="input w-20 focus:outline-none focus:ring-0"
              />
            </div>
          );
        })}
      </div>
      <div className="flex gap-2">
        <button className="btn" onClick={splitEqually} type="button">
          Split equally
        </button>
        <button className="btn-primary" onClick={save} type="button">
          Save
        </button>
      </div>
    </div>
  );
}


