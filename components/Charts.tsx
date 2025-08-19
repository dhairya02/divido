"use client";
import dynamic from "next/dynamic";
import { useMemo } from "react";

const Plot = dynamic(() => import("react-plotly.js"), { ssr: false });

export function BreakdownByPerson({
  data,
}: {
  data: { name: string; preTaxCents: number; taxCents: number; tipCents: number }[];
}) {
  const names = data.map((d) => d.name);
  const pre = data.map((d) => d.preTaxCents / 100);
  const tax = data.map((d) => d.taxCents / 100);
  const tip = data.map((d) => d.tipCents / 100);

  return (
    <Plot
      data={[
        { type: "bar", x: names, y: pre, name: "Pre-tax" },
        { type: "bar", x: names, y: tax, name: "Tax" },
        { type: "bar", x: names, y: tip, name: "Tip" },
      ]}
      layout={{
        barmode: "stack",
        paper_bgcolor: "rgba(0,0,0,0)",
        plot_bgcolor: "rgba(0,0,0,0)",
        margin: { t: 20, r: 10, l: 40, b: 40 },
        legend: { orientation: "h" },
        colorway: ["#6f8bff", "#e8ffa3", "#b794d9"],
      }}
      style={{ width: "100%", height: 320 }}
      config={{ displayModeBar: false }}
    />
  );
}

export function ItemsByPerson({
  participants,
  byItem,
}: {
  participants: { id: string; name: string }[];
  byItem: { itemId: string; itemName?: string; allocations: { participantId: string; cents: number }[] }[];
}) {
  const traces = useMemo(() => {
    return participants.map((p) => ({
      type: "bar" as const,
      name: p.name,
      x: byItem.map((i) => i.itemName ?? i.itemId),
      y: byItem.map((i) => (i.allocations.find((a) => a.participantId === p.id)?.cents ?? 0) / 100),
    }));
  }, [participants, byItem]);

  return (
    <Plot
      data={traces}
      layout={{
        barmode: "stack",
        paper_bgcolor: "rgba(0,0,0,0)",
        plot_bgcolor: "rgba(0,0,0,0)",
        margin: { t: 20, r: 10, l: 40, b: 80 },
        legend: { orientation: "h" },
        colorway: ["#6f8bff", "#e8ffa3", "#b794d9", "#c77dff"],
        xaxis: { tickangle: -30 },
      }}
      style={{ width: "100%", height: 360 }}
      config={{ displayModeBar: false }}
    />
  );
}


