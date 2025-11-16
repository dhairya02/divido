import { roundHalfUp, fractionalPart, assert, stableSortBy } from "./utils";

export type CalcInput = {
  items: { id: string; priceCents: number; taxable?: boolean; taxRatePct?: number }[];
  participants: { id: string; name: string }[];
  shares: { itemId: string; participantId: string; weight: number }[];
  taxRatePct: number;
  tipRatePct: number;
  taxMode?: "GLOBAL" | "ITEM";
  convenienceFeeRatePct?: number;
};

export type CalcOutput = {
  billTotals: {
    subtotalCents: number;
    taxCents: number;
    tipCents: number;
    convenienceFeeCents: number;
    grandTotalCents: number;
  };
  participants: {
    participantId: string;
    name: string;
    preTaxCents: number;
    taxCents: number;
    tipCents: number;
    totalOwedCents: number;
  }[];
  byItem: {
    itemId: string;
    allocations: { participantId: string; cents: number }[];
  }[];
};

export function calculateSplit(input: CalcInput): CalcOutput {
  const { items, participants, shares, taxRatePct, tipRatePct, taxMode = "GLOBAL", convenienceFeeRatePct = 0 } = input;

  // 1. Subtotal
  const subtotalCents = items.reduce((acc, it) => acc + it.priceCents, 0);

  // 2-3. Item splits with weights, round-half-up per participant and fix rounding drift
  const participantIdToPreTaxCents = new Map<string, number>();
  for (const p of participants) participantIdToPreTaxCents.set(p.id, 0);

  const byItem: { itemId: string; allocations: { participantId: string; cents: number }[] }[] = [];

  for (const item of items) {
    const itemShares = shares.filter((s) => s.itemId === item.id && s.weight > 0);
    if (itemShares.length === 0) {
      throw new Error(`Item "${item.id}" has no shares assigned.`);
    }

    const totalWeight = itemShares.reduce((acc, s) => acc + s.weight, 0);
    // Normalized allocations
    const exactAllocations = itemShares.map((s) => ({
      participantId: s.participantId,
      exact: (item.priceCents * s.weight) / totalWeight,
    }));

    const rounded = exactAllocations.map((ea) => ({
      participantId: ea.participantId,
      exact: ea.exact,
      rounded: roundHalfUp(ea.exact),
      frac: fractionalPart(ea.exact),
    }));

    let sumRounded = rounded.reduce((acc, r) => acc + r.rounded, 0);
    const delta = item.priceCents - sumRounded; // how many pennies to adjust

    if (delta !== 0) {
      const direction = Math.sign(delta); // +1 add pennies, -1 remove pennies
      const count = Math.abs(delta);
      const sorted = rounded
        .slice()
        .sort((a, b) => {
          // For adding pennies: larger fractional parts first
          // For removing pennies: smaller fractional parts first
          const primary = direction > 0 ? b.frac - a.frac : a.frac - b.frac;
          if (primary !== 0) return primary;
          // tiebreak by participantId for determinism
          return a.participantId.localeCompare(b.participantId);
        });
      for (let i = 0; i < count; i++) {
        sorted[i % sorted.length].rounded += direction;
      }
      // Recompute sum after distribution
      sumRounded = sorted.reduce((acc, r) => acc + r.rounded, 0);
      // Place back into rounded map
      const byId = new Map(sorted.map((r) => [r.participantId, r.rounded] as const));
      for (const r of rounded) r.rounded = byId.get(r.participantId) ?? r.rounded;
    }

    // Accumulate pre-tax per participant
    const itemAllocations: { participantId: string; cents: number }[] = [];
    for (const r of rounded) {
      const prev = participantIdToPreTaxCents.get(r.participantId) ?? 0;
      participantIdToPreTaxCents.set(r.participantId, prev + r.rounded);
      itemAllocations.push({ participantId: r.participantId, cents: r.rounded });
    }
    byItem.push({ itemId: item.id, allocations: itemAllocations });
  }

  // 5. Pools
  let taxCents = 0;
  if (taxMode === "GLOBAL") {
    const taxableSubtotal = subtotalCents;
    taxCents = roundHalfUp((taxableSubtotal * taxRatePct) / 100);
  } else {
    // Sum item-level tax based on each item's specific tax rate (or 0)
    taxCents = items.reduce((acc, it) => {
      if (it.taxable === false) return acc;
      const rate = typeof it.taxRatePct === "number" ? it.taxRatePct : taxRatePct;
      return acc + roundHalfUp((it.priceCents * rate) / 100);
    }, 0);
  }
  const tipCents = roundHalfUp((subtotalCents * tipRatePct) / 100);

  const preTaxTotals = participants.map((p) => ({
    participantId: p.id,
    name: p.name,
    preTaxCents: participantIdToPreTaxCents.get(p.id) ?? 0,
  }));

  // 6. Allocate pools proportionally using floor + remainder distribution
  const poolAllocate = (pool: number) => {
    if (pool === 0 || subtotalCents === 0) {
      return preTaxTotals.map(() => 0);
    }
    const exacts = preTaxTotals.map((pt) => (pool * pt.preTaxCents) / subtotalCents);
    const floors = exacts.map((e) => Math.floor(e));
    let sumFloors = floors.reduce((a, b) => a + b, 0);
    let leftover = pool - sumFloors;
    if (leftover > 0) {
      const order = preTaxTotals
        .map((pt, idx) => ({ idx, frac: fractionalPart(exacts[idx]) }))
        .sort((a, b) => b.frac - a.frac || (preTaxTotals[a.idx].participantId.localeCompare(preTaxTotals[b.idx].participantId)));
      for (let i = 0; i < leftover; i++) floors[order[i % order.length].idx] += 1;
      sumFloors = floors.reduce((a, b) => a + b, 0);
    }
    return floors;
  };

  const feeCents = roundHalfUp((subtotalCents * convenienceFeeRatePct) / 100);
  const taxAlloc = poolAllocate(taxCents);
  const tipAlloc = poolAllocate(tipCents);
  const feeAlloc = poolAllocate(feeCents);

  const participantsOut = preTaxTotals.map((pt, idx) => {
    const tax = taxAlloc[idx];
    const tip = tipAlloc[idx];
    const fee = feeAlloc[idx];
    const total = pt.preTaxCents + tax + tip + fee;
    return {
      participantId: pt.participantId,
      name: pt.name,
      preTaxCents: pt.preTaxCents,
      taxCents: tax,
      tipCents: tip,
      convenienceFeeCents: fee,
      totalOwedCents: total,
    };
  });

  // 8. Assert exactness
  const sumOwed = participantsOut.reduce((acc, p) => acc + p.totalOwedCents, 0);
  const grandTotal = subtotalCents + taxCents + tipCents + feeCents;
  assert(sumOwed === grandTotal, "Totals do not add up exactly.");

  return {
    billTotals: {
      subtotalCents,
      taxCents,
      tipCents,
      convenienceFeeCents: feeCents,
      grandTotalCents: grandTotal,
    },
    participants: participantsOut,
    byItem,
  };
}


