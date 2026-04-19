import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../models/bill.dart';
import '../models/contact.dart';
import '../utils/calc.dart';
import 'local_db.dart';

/// Single point of truth for everything the UI needs. Wraps the SQLite
/// schema in `LocalDatabase` and exposes typed operations that mirror the
/// shape of the old `DividoApi` so screens can stay focused on UI.
class LocalRepository {
  LocalRepository(this.local);
  final LocalDatabase local;

  // ----- Contacts -----------------------------------------------------------

  Future<List<Contact>> listContacts() async {
    final rows = await local.db.query(
      'contacts',
      where: 'is_temporary = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_contactFromRow).toList();
  }

  Future<Contact> createContact({
    required String name,
    String? email,
    String? phone,
    String? venmo,
    String? cashapp,
    bool isTemporary = false,
  }) async {
    final id = newId();
    await local.db.insert('contacts', {
      'id': id,
      'name': name.trim(),
      'email': _nullIfEmpty(email),
      'phone': _nullIfEmpty(phone),
      'venmo': _nullIfEmpty(venmo),
      'cashapp': _nullIfEmpty(cashapp),
      'is_temporary': isTemporary ? 1 : 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return (await getContact(id))!;
  }

  Future<Contact?> getContact(String id) async {
    final rows = await local.db.query('contacts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _contactFromRow(rows.first);
  }

  Future<Contact> updateContact(String id, Map<String, dynamic> patch) async {
    final updates = <String, Object?>{};
    if (patch.containsKey('name')) updates['name'] = (patch['name'] as String).trim();
    if (patch.containsKey('email')) updates['email'] = _nullIfEmpty(patch['email'] as String?);
    if (patch.containsKey('phone')) updates['phone'] = _nullIfEmpty(patch['phone'] as String?);
    if (patch.containsKey('venmo')) updates['venmo'] = _nullIfEmpty(patch['venmo'] as String?);
    if (patch.containsKey('cashapp')) updates['cashapp'] = _nullIfEmpty(patch['cashapp'] as String?);
    if (updates.isNotEmpty) {
      await local.db.update('contacts', updates, where: 'id = ?', whereArgs: [id]);
    }
    return (await getContact(id))!;
  }

  Future<void> deleteContact(String id) async {
    final selfId = await getSelfContactId();
    if (selfId == id) {
      throw StateError('Cannot delete the contact representing you.');
    }
    await local.db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ----- Bills --------------------------------------------------------------

  Future<List<Bill>> listBills() async {
    final rows = await local.db.query('bills', orderBy: 'created_at DESC');
    return rows.map(_billFromRow).toList();
  }

  Future<String> createBill({
    required String title,
    String? venue,
    required int subtotalCents,
    required double taxRatePct,
    required double tipRatePct,
    double convenienceFeeRatePct = 0,
    String currency = 'USD',
    String taxMode = 'GLOBAL',
    List<String> participantContactIds = const [],
    String? paidByContactId,
  }) async {
    final id = newId();
    await local.db.transaction((txn) async {
      await txn.insert('bills', {
        'id': id,
        'title': title.trim(),
        'venue': _nullIfEmpty(venue),
        'date': DateTime.now().millisecondsSinceEpoch,
        'subtotal_cents': subtotalCents,
        'tax_rate_pct': taxRatePct,
        'tip_rate_pct': tipRatePct,
        'convenience_fee_rate_pct': convenienceFeeRatePct,
        'currency': currency,
        'tax_mode': taxMode,
        'paid_by_contact_id': paidByContactId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      for (final cid in participantContactIds) {
        await txn.insert('bill_participants', {
          'id': newId(),
          'bill_id': id,
          'contact_id': cid,
          'note': null,
        });
      }
    });
    return id;
  }

  Future<BillDetails> getBill(String id) async {
    final billRows =
        await local.db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (billRows.isEmpty) {
      throw StateError('Bill not found');
    }
    final bill = _billFromRow(billRows.first);

    final partRows = await local.db.rawQuery('''
      SELECT bp.id AS bp_id, bp.contact_id AS contact_id, c.name AS name
      FROM bill_participants bp
      JOIN contacts c ON c.id = bp.contact_id
      WHERE bp.bill_id = ?
      ORDER BY c.name COLLATE NOCASE ASC
    ''', [id]);
    final participants = partRows
        .map((r) => BillParticipant(
              id: r['bp_id'] as String,
              name: r['name'] as String,
              contactId: r['contact_id'] as String,
            ))
        .toList();

    final itemRows = await local.db.query(
      'items',
      where: 'bill_id = ?',
      whereArgs: [id],
      orderBy: 'rowid ASC',
    );
    final items = itemRows.map(_itemFromRow).toList();

    final shareRows = await local.db.rawQuery('''
      SELECT s.id, s.item_id, s.participant_id, s.weight
      FROM item_shares s
      JOIN items i ON i.id = s.item_id
      WHERE i.bill_id = ?
    ''', [id]);
    final shares = shareRows
        .map((r) => ItemShare(
              id: r['id'] as String,
              itemId: r['item_id'] as String,
              participantId: r['participant_id'] as String,
              weight: (r['weight'] as num).toDouble(),
            ))
        .toList();

    return BillDetails(
      bill: bill,
      participants: participants,
      items: items,
      shares: shares,
    );
  }

  Future<void> deleteBill(String id) async {
    await local.db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBill(String id, Map<String, dynamic> patch) async {
    final updates = <String, Object?>{};
    if (patch.containsKey('subtotalCents')) {
      updates['subtotal_cents'] = patch['subtotalCents'];
    }
    if (patch.containsKey('taxRatePct')) updates['tax_rate_pct'] = patch['taxRatePct'];
    if (patch.containsKey('tipRatePct')) updates['tip_rate_pct'] = patch['tipRatePct'];
    if (patch.containsKey('convenienceFeeRatePct')) {
      updates['convenience_fee_rate_pct'] = patch['convenienceFeeRatePct'];
    }
    if (patch.containsKey('paidByContactId')) {
      updates['paid_by_contact_id'] = patch['paidByContactId'];
    }
    if (updates.isNotEmpty) {
      await local.db.update('bills', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  // ----- Items / shares / participants --------------------------------------

  Future<Item> addItem(
    String billId, {
    required String name,
    required int priceCents,
    int quantity = 1,
    bool taxable = true,
    double? taxRatePct,
  }) async {
    final id = newId();
    await local.db.insert('items', {
      'id': id,
      'bill_id': billId,
      'name': name.trim(),
      'price_cents': priceCents,
      'quantity': quantity,
      'taxable': taxable ? 1 : 0,
      'tax_rate_pct': taxRatePct ?? 0,
    });
    return Item(
      id: id,
      billId: billId,
      name: name.trim(),
      priceCents: priceCents,
      quantity: quantity,
      taxable: taxable,
      taxRatePct: taxRatePct ?? 0,
    );
  }

  Future<void> updateItem(
      String billId, String itemId, Map<String, dynamic> patch) async {
    final updates = <String, Object?>{};
    if (patch.containsKey('name')) updates['name'] = (patch['name'] as String).trim();
    if (patch.containsKey('priceCents')) updates['price_cents'] = patch['priceCents'];
    if (patch.containsKey('quantity')) updates['quantity'] = patch['quantity'];
    if (patch.containsKey('taxable')) {
      updates['taxable'] = (patch['taxable'] as bool) ? 1 : 0;
    }
    if (patch.containsKey('taxRatePct')) updates['tax_rate_pct'] = patch['taxRatePct'];
    if (updates.isEmpty) return;
    await local.db.update(
      'items',
      updates,
      where: 'id = ? AND bill_id = ?',
      whereArgs: [itemId, billId],
    );
  }

  Future<void> deleteItem(String billId, String itemId) async {
    await local.db.delete(
      'items',
      where: 'id = ? AND bill_id = ?',
      whereArgs: [itemId, billId],
    );
  }

  Future<void> upsertShare(
    String billId, {
    required String itemId,
    required String participantId,
    required double weight,
  }) async {
    if (weight <= 0) {
      await local.db.delete(
        'item_shares',
        where: 'item_id = ? AND participant_id = ?',
        whereArgs: [itemId, participantId],
      );
      return;
    }
    await local.db.insert(
      'item_shares',
      {
        'id': newId(),
        'item_id': itemId,
        'participant_id': participantId,
        'weight': weight,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    // If the row already existed, the insert above is ignored — update its
    // weight in that case.
    await local.db.update(
      'item_shares',
      {'weight': weight},
      where: 'item_id = ? AND participant_id = ?',
      whereArgs: [itemId, participantId],
    );
  }

  Future<BillParticipant> addParticipant(String billId, String contactId) async {
    final id = newId();
    await local.db.insert(
      'bill_participants',
      {
        'id': id,
        'bill_id': billId,
        'contact_id': contactId,
        'note': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    final row = await local.db.rawQuery('''
      SELECT bp.id, c.name FROM bill_participants bp
      JOIN contacts c ON c.id = bp.contact_id
      WHERE bp.bill_id = ? AND bp.contact_id = ?
    ''', [billId, contactId]);
    return BillParticipant(
      id: (row.first['id'] as String?) ?? id,
      name: row.first['name'] as String,
      contactId: contactId,
    );
  }

  // ----- Calculation --------------------------------------------------------

  Future<CalcResult> calculate(String billId) async {
    final d = await getBill(billId);
    if (d.items.isEmpty) {
      throw StateError('Add at least one item before calculating.');
    }
    if (d.participants.isEmpty) {
      throw StateError('Add at least one participant before calculating.');
    }
    final out = calculateSplit(
      items: d.items
          .map((i) => CalcItem(
                id: i.id,
                priceCents: i.priceCents,
                taxable: i.taxable,
                taxRatePct: i.taxRatePct,
              ))
          .toList(),
      participants: d.participants
          .map((p) => CalcParticipant(id: p.id, name: p.name))
          .toList(),
      shares: d.shares
          .map((s) => CalcShare(
                itemId: s.itemId,
                participantId: s.participantId,
                weight: s.weight,
              ))
          .toList(),
      taxRatePct: d.bill.taxRatePct,
      tipRatePct: d.bill.tipRatePct,
      taxMode: d.bill.taxMode,
      convenienceFeeRatePct: d.bill.convenienceFeeRatePct,
    );
    return CalcResult(
      billTotals: BillTotals(
        subtotalCents: out.billTotals.subtotalCents,
        taxCents: out.billTotals.taxCents,
        tipCents: out.billTotals.tipCents,
        convenienceFeeCents: out.billTotals.convenienceFeeCents,
        grandTotalCents: out.billTotals.grandTotalCents,
      ),
      participants: out.participants
          .map((p) => ParticipantCalculation(
                participantId: p.participantId,
                name: p.name,
                preTaxCents: p.preTaxCents,
                taxCents: p.taxCents,
                tipCents: p.tipCents,
                convenienceFeeCents: p.convenienceFeeCents,
                totalOwedCents: p.totalOwedCents,
              ))
          .toList(),
    );
  }

  // ----- Profile / settings -------------------------------------------------

  Future<String?> getSelfContactId() => getSetting('self_contact_id');

  Future<String?> getSetting(String key) async {
    final rows = await local.db
        .query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String? value) async {
    if (value == null) {
      await local.db.delete('settings', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await local.db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns counts for the Account screen.
  Future<({int bills, int contacts})> getStats() async {
    final b = await local.db.rawQuery('SELECT COUNT(*) AS c FROM bills');
    final c = await local.db.rawQuery(
        'SELECT COUNT(*) AS c FROM contacts WHERE is_temporary = 0');
    return (
      bills: ((b.first['c'] as num?)?.toInt() ?? 0),
      contacts: ((c.first['c'] as num?)?.toInt() ?? 0),
    );
  }

  /// Wipes all data (handy for tests and the "reset" button).
  Future<void> resetEverything() async {
    await local.db.transaction((txn) async {
      await txn.delete('item_shares');
      await txn.delete('items');
      await txn.delete('bill_participants');
      await txn.delete('bills');
      await txn.delete('contacts');
      await txn.delete('settings');
    });
  }

  // ----- Helpers ------------------------------------------------------------

  Contact _contactFromRow(Map<String, Object?> r) => Contact(
        id: r['id'] as String,
        name: r['name'] as String,
        email: r['email'] as String?,
        phone: r['phone'] as String?,
        venmo: r['venmo'] as String?,
        cashapp: r['cashapp'] as String?,
        isTemporary: ((r['is_temporary'] as int?) ?? 0) == 1,
      );

  Bill _billFromRow(Map<String, Object?> r) => Bill(
        id: r['id'] as String,
        title: r['title'] as String,
        venue: r['venue'] as String?,
        date: DateTime.fromMillisecondsSinceEpoch((r['date'] as num).toInt()),
        subtotalCents: (r['subtotal_cents'] as num).toInt(),
        taxRatePct: (r['tax_rate_pct'] as num).toDouble(),
        tipRatePct: (r['tip_rate_pct'] as num).toDouble(),
        convenienceFeeRatePct: (r['convenience_fee_rate_pct'] as num).toDouble(),
        currency: (r['currency'] as String?) ?? 'USD',
        taxMode: (r['tax_mode'] as String?) ?? 'GLOBAL',
        paidByContactId: r['paid_by_contact_id'] as String?,
      );

  Item _itemFromRow(Map<String, Object?> r) => Item(
        id: r['id'] as String,
        billId: r['bill_id'] as String,
        name: r['name'] as String,
        priceCents: (r['price_cents'] as num).toInt(),
        quantity: ((r['quantity'] as num?) ?? 1).toInt(),
        taxable: ((r['taxable'] as int?) ?? 1) == 1,
        taxRatePct: (r['tax_rate_pct'] as num).toDouble(),
      );

  String? _nullIfEmpty(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
