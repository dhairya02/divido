export function formatCents(amountCents: number, currency: string = "USD"): string {
  const formatter = new Intl.NumberFormat(undefined, {
    style: "currency",
    currency,
  });
  return formatter.format(amountCents / 100);
}


