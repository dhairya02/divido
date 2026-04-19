/// Dart port of `web/lib/calc.ts`.
///
/// Used to preview splits offline (e.g. before a bill is persisted) and to
/// keep the logic available even when the device is offline. Behaviour must
/// stay byte-for-byte equivalent with the canonical TypeScript version:
///
///  - round half up (away from zero)
///  - distribute rounding remainder to participants with the largest fractional
///    part (ties broken by participantId)
///  - allocate tax/tip/fee pools by floor + remainder distribution
///  - assert sums equal the grand total
class CalcItem {
  final String id;
  final int priceCents;
  final bool taxable;
  final double? taxRatePct;
  CalcItem({
    required this.id,
    required this.priceCents,
    this.taxable = true,
    this.taxRatePct,
  });
}

class CalcParticipant {
  final String id;
  final String name;
  CalcParticipant({required this.id, required this.name});
}

class CalcShare {
  final String itemId;
  final String participantId;
  final double weight;
  CalcShare({
    required this.itemId,
    required this.participantId,
    required this.weight,
  });
}

class CalcParticipantResult {
  final String participantId;
  final String name;
  final int preTaxCents;
  final int taxCents;
  final int tipCents;
  final int convenienceFeeCents;
  final int totalOwedCents;
  CalcParticipantResult({
    required this.participantId,
    required this.name,
    required this.preTaxCents,
    required this.taxCents,
    required this.tipCents,
    required this.convenienceFeeCents,
    required this.totalOwedCents,
  });
}

class CalcTotals {
  final int subtotalCents;
  final int taxCents;
  final int tipCents;
  final int convenienceFeeCents;
  final int grandTotalCents;
  CalcTotals({
    required this.subtotalCents,
    required this.taxCents,
    required this.tipCents,
    required this.convenienceFeeCents,
    required this.grandTotalCents,
  });
}

class CalcOutput {
  final CalcTotals billTotals;
  final List<CalcParticipantResult> participants;
  CalcOutput({required this.billTotals, required this.participants});
}

int roundHalfUp(double value) {
  if (value.isNaN || !value.isFinite) return 0;
  return value >= 0 ? (value + 0.5).floor() : (value - 0.5).ceil();
}

double fractionalPart(double value) => value - value.floor();

CalcOutput calculateSplit({
  required List<CalcItem> items,
  required List<CalcParticipant> participants,
  required List<CalcShare> shares,
  required double taxRatePct,
  required double tipRatePct,
  String taxMode = 'GLOBAL',
  double convenienceFeeRatePct = 0,
}) {
  final subtotalCents = items.fold<int>(0, (a, it) => a + it.priceCents);

  final preTax = <String, int>{
    for (final p in participants) p.id: 0,
  };

  for (final item in items) {
    final itemShares = shares
        .where((s) => s.itemId == item.id && s.weight > 0)
        .toList();
    if (itemShares.isEmpty) {
      throw StateError('Item "${item.id}" has no shares assigned.');
    }
    final totalWeight = itemShares.fold<double>(0, (a, s) => a + s.weight);
    final exact = itemShares
        .map((s) => _Alloc(
              participantId: s.participantId,
              exact: (item.priceCents * s.weight) / totalWeight,
            ))
        .toList();
    for (final a in exact) {
      a.rounded = roundHalfUp(a.exact);
      a.frac = fractionalPart(a.exact);
    }
    int sumRounded = exact.fold<int>(0, (a, r) => a + r.rounded);
    final delta = item.priceCents - sumRounded;
    if (delta != 0) {
      final direction = delta.sign;
      final count = delta.abs();
      final sorted = [...exact]..sort((a, b) {
          final primary = direction > 0 ? b.frac - a.frac : a.frac - b.frac;
          if (primary != 0) return primary.compareTo(0) < 0 ? -1 : 1;
          return a.participantId.compareTo(b.participantId);
        });
      for (int i = 0; i < count; i++) {
        sorted[i % sorted.length].rounded += direction;
      }
    }
    for (final a in exact) {
      preTax[a.participantId] = (preTax[a.participantId] ?? 0) + a.rounded;
    }
  }

  int taxCents;
  if (taxMode == 'GLOBAL') {
    taxCents = roundHalfUp((subtotalCents * taxRatePct) / 100);
  } else {
    taxCents = items.fold<int>(0, (a, it) {
      if (!it.taxable) return a;
      final rate = it.taxRatePct ?? taxRatePct;
      return a + roundHalfUp((it.priceCents * rate) / 100);
    });
  }
  final tipCents = roundHalfUp((subtotalCents * tipRatePct) / 100);
  final feeCents = roundHalfUp((subtotalCents * convenienceFeeRatePct) / 100);

  List<int> allocatePool(int pool) {
    if (pool == 0 || subtotalCents == 0) {
      return List<int>.filled(participants.length, 0);
    }
    final exacts = participants
        .map((p) => (pool * (preTax[p.id] ?? 0)) / subtotalCents)
        .toList();
    final floors = exacts.map((e) => e.floor()).toList();
    final sumFloors = floors.fold<int>(0, (a, b) => a + b);
    final leftover = pool - sumFloors;
    if (leftover > 0) {
      final order = List<int>.generate(participants.length, (i) => i)
        ..sort((a, b) {
          final cmp = fractionalPart(exacts[b]).compareTo(fractionalPart(exacts[a]));
          if (cmp != 0) return cmp;
          return participants[a].id.compareTo(participants[b].id);
        });
      for (int i = 0; i < leftover; i++) {
        floors[order[i % order.length]] += 1;
      }
    }
    return floors;
  }

  final taxAlloc = allocatePool(taxCents);
  final tipAlloc = allocatePool(tipCents);
  final feeAlloc = allocatePool(feeCents);

  final out = <CalcParticipantResult>[];
  for (var i = 0; i < participants.length; i++) {
    final p = participants[i];
    final pre = preTax[p.id] ?? 0;
    final t = taxAlloc[i];
    final tip = tipAlloc[i];
    final fee = feeAlloc[i];
    out.add(CalcParticipantResult(
      participantId: p.id,
      name: p.name,
      preTaxCents: pre,
      taxCents: t,
      tipCents: tip,
      convenienceFeeCents: fee,
      totalOwedCents: pre + t + tip + fee,
    ));
  }

  final grand = subtotalCents + taxCents + tipCents + feeCents;
  final sumOwed = out.fold<int>(0, (a, r) => a + r.totalOwedCents);
  if (sumOwed != grand) {
    throw StateError('Totals do not add up exactly.');
  }

  return CalcOutput(
    billTotals: CalcTotals(
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      tipCents: tipCents,
      convenienceFeeCents: feeCents,
      grandTotalCents: grand,
    ),
    participants: out,
  );
}

class _Alloc {
  final String participantId;
  final double exact;
  int rounded = 0;
  double frac = 0;
  _Alloc({required this.participantId, required this.exact});
}
