"use client";
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
      <div className="flex gap-2 flex-wrap items-center">
        {participants.map((p) => (
          <label key={p.id} className="flex items-center gap-2">
            <span className="w-24 text-sm">{p.name}</span>
            <input
              type="number"
              min={0}
              step={0.5}
              value={weights[p.id] ?? 0}
              onChange={(e) => setWeight(p.id, Number(e.target.value))}
              className="input w-24"
            />
          </label>
        ))}
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


