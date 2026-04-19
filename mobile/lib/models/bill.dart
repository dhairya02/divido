import 'contact.dart';

class Bill {
  final String id;
  final String title;
  final String? venue;
  final DateTime date;
  final int subtotalCents;
  final double taxRatePct;
  final double tipRatePct;
  final double convenienceFeeRatePct;
  final String currency;
  final String taxMode; // GLOBAL or ITEM
  final String? paidByContactId;

  Bill({
    required this.id,
    required this.title,
    this.venue,
    required this.date,
    required this.subtotalCents,
    required this.taxRatePct,
    required this.tipRatePct,
    this.convenienceFeeRatePct = 0,
    this.currency = 'USD',
    this.taxMode = 'GLOBAL',
    this.paidByContactId,
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        title: json['title'] as String,
        venue: json['venue'] as String?,
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        subtotalCents: (json['subtotalCents'] as num).toInt(),
        taxRatePct: (json['taxRatePct'] as num).toDouble(),
        tipRatePct: (json['tipRatePct'] as num).toDouble(),
        convenienceFeeRatePct:
            ((json['convenienceFeeRatePct'] ?? 0) as num).toDouble(),
        currency: (json['currency'] as String?) ?? 'USD',
        taxMode: (json['taxMode'] as String?) ?? 'GLOBAL',
        paidByContactId: json['paidByContactId'] as String?,
      );
}

class Item {
  final String id;
  final String billId;
  final String name;
  final int priceCents;
  final int quantity;
  final bool taxable;
  final double taxRatePct;

  Item({
    required this.id,
    required this.billId,
    required this.name,
    required this.priceCents,
    this.quantity = 1,
    this.taxable = true,
    this.taxRatePct = 0,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        billId: (json['billId'] as String?) ?? '',
        name: json['name'] as String,
        priceCents: (json['priceCents'] as num).toInt(),
        quantity: ((json['quantity'] ?? 1) as num).toInt(),
        taxable: (json['taxable'] as bool?) ?? true,
        taxRatePct: ((json['taxRatePct'] ?? 0) as num).toDouble(),
      );
}

class ItemShare {
  final String id;
  final String itemId;
  final String participantId;
  final double weight;

  ItemShare({
    required this.id,
    required this.itemId,
    required this.participantId,
    required this.weight,
  });

  factory ItemShare.fromJson(Map<String, dynamic> json) => ItemShare(
        id: (json['id'] as String?) ?? '',
        itemId: json['itemId'] as String,
        participantId: json['participantId'] as String,
        weight: (json['weight'] as num).toDouble(),
      );
}

class BillParticipant {
  final String id;
  final String name;
  final String contactId;

  BillParticipant({
    required this.id,
    required this.name,
    required this.contactId,
  });

  factory BillParticipant.fromJson(Map<String, dynamic> json) =>
      BillParticipant(
        id: json['id'] as String,
        name: json['name'] as String,
        contactId: (json['contactId'] as String?) ?? '',
      );
}

class BillDetails {
  final Bill bill;
  final List<BillParticipant> participants;
  final List<Item> items;
  final List<ItemShare> shares;

  BillDetails({
    required this.bill,
    required this.participants,
    required this.items,
    required this.shares,
  });

  factory BillDetails.fromJson(Map<String, dynamic> json) {
    final billJson = json['bill'] as Map<String, dynamic>;
    return BillDetails(
      bill: Bill.fromJson(billJson),
      participants: (json['participants'] as List<dynamic>)
          .map((p) => BillParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>)
          .map((i) => Item.fromJson(i as Map<String, dynamic>))
          .toList(),
      shares: (json['shares'] as List<dynamic>)
          .map((s) => ItemShare.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParticipantCalculation {
  final String participantId;
  final String name;
  final int preTaxCents;
  final int taxCents;
  final int tipCents;
  final int convenienceFeeCents;
  final int totalOwedCents;
  final String? contactId;

  ParticipantCalculation({
    required this.participantId,
    required this.name,
    required this.preTaxCents,
    required this.taxCents,
    required this.tipCents,
    required this.convenienceFeeCents,
    required this.totalOwedCents,
    this.contactId,
  });

  factory ParticipantCalculation.fromJson(Map<String, dynamic> json) =>
      ParticipantCalculation(
        participantId: json['participantId'] as String,
        name: json['name'] as String,
        preTaxCents: (json['preTaxCents'] as num).toInt(),
        taxCents: (json['taxCents'] as num).toInt(),
        tipCents: (json['tipCents'] as num).toInt(),
        convenienceFeeCents:
            ((json['convenienceFeeCents'] ?? 0) as num).toInt(),
        totalOwedCents: (json['totalOwedCents'] as num).toInt(),
        contactId: json['contactId'] as String?,
      );
}

class BillTotals {
  final int subtotalCents;
  final int taxCents;
  final int tipCents;
  final int convenienceFeeCents;
  final int grandTotalCents;

  BillTotals({
    required this.subtotalCents,
    required this.taxCents,
    required this.tipCents,
    required this.convenienceFeeCents,
    required this.grandTotalCents,
  });

  factory BillTotals.fromJson(Map<String, dynamic> json) => BillTotals(
        subtotalCents: (json['subtotalCents'] as num).toInt(),
        taxCents: (json['taxCents'] as num).toInt(),
        tipCents: (json['tipCents'] as num).toInt(),
        convenienceFeeCents:
            ((json['convenienceFeeCents'] ?? 0) as num).toInt(),
        grandTotalCents: (json['grandTotalCents'] as num).toInt(),
      );
}

class CalcResult {
  final BillTotals billTotals;
  final List<ParticipantCalculation> participants;

  CalcResult({required this.billTotals, required this.participants});

  factory CalcResult.fromJson(Map<String, dynamic> json) => CalcResult(
        billTotals:
            BillTotals.fromJson(json['billTotals'] as Map<String, dynamic>),
        participants: (json['participants'] as List<dynamic>)
            .map((p) =>
                ParticipantCalculation.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// Keep Contact import accessible to consumers via this barrel.
typedef DividoContact = Contact;
