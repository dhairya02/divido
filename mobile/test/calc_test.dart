import 'package:divido_mobile/utils/calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateSplit', () {
    test('splits a simple bill exactly with rounding correction', () {
      final out = calculateSplit(
        items: [
          CalcItem(id: 'i1', priceCents: 1800),
          CalcItem(id: 'i2', priceCents: 5400),
        ],
        participants: [
          CalcParticipant(id: 'p1', name: 'Alex'),
          CalcParticipant(id: 'p2', name: 'Taylor'),
        ],
        shares: [
          CalcShare(itemId: 'i1', participantId: 'p1', weight: 1),
          CalcShare(itemId: 'i1', participantId: 'p2', weight: 1),
          CalcShare(itemId: 'i2', participantId: 'p2', weight: 1),
        ],
        taxRatePct: 8.875,
        tipRatePct: 20,
        convenienceFeeRatePct: 3,
      );

      expect(out.billTotals.subtotalCents, 7200);
      // sum-of-owed must equal grand total (asserted internally too).
      final sum = out.participants
          .fold<int>(0, (a, p) => a + p.totalOwedCents);
      expect(sum, out.billTotals.grandTotalCents);
    });

    test('throws when an item has no shares', () {
      expect(
        () => calculateSplit(
          items: [CalcItem(id: 'i1', priceCents: 100)],
          participants: [CalcParticipant(id: 'p1', name: 'A')],
          shares: const [],
          taxRatePct: 0,
          tipRatePct: 0,
        ),
        throwsStateError,
      );
    });
  });
}
