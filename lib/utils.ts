export function roundHalfUp(value: number): number {
  if (Number.isNaN(value) || !Number.isFinite(value)) return 0;
  return value >= 0 ? Math.floor(value + 0.5) : Math.ceil(value - 0.5);
}

export function fractionalPart(value: number): number {
  const floorValue = Math.floor(value);
  return value - floorValue;
}

export function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

export function stableSortBy<T>(arr: T[], selector: (x: T) => number | string): T[] {
  return arr
    .map((v, idx) => ({ v, idx }))
    .sort((a, b) => {
      const aa = selector(a.v);
      const bb = selector(b.v);
      if (aa < bb) return -1;
      if (aa > bb) return 1;
      return a.idx - b.idx;
    })
    .map((x) => x.v);
}


