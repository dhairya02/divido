import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the on-device SQLite database that backs every screen.
///
/// The schema mirrors the Prisma models in `web/prisma/schema.prisma` minus
/// anything related to multi-user accounts (`User`, sessions, password
/// hashes…). The mobile app is single-user by design — the device IS the
/// user — so we only persist the data that a single person needs to split
/// bills with their friends.
class LocalDatabase {
  LocalDatabase._(this.db);
  final Database db;

  static Future<LocalDatabase> open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'divido.db');
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _create,
    );
    return LocalDatabase._(db);
  }

  static Future<void> _create(Database db, int _) async {
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        venmo TEXT,
        cashapp TEXT,
        is_temporary INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        venue TEXT,
        date INTEGER NOT NULL,
        subtotal_cents INTEGER NOT NULL,
        tax_rate_pct REAL NOT NULL DEFAULT 0,
        tip_rate_pct REAL NOT NULL DEFAULT 0,
        convenience_fee_rate_pct REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD',
        tax_mode TEXT NOT NULL DEFAULT 'GLOBAL',
        paid_by_contact_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(paid_by_contact_id) REFERENCES contacts(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price_cents INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        taxable INTEGER NOT NULL DEFAULT 1,
        tax_rate_pct REAL NOT NULL DEFAULT 0,
        FOREIGN KEY(bill_id) REFERENCES bills(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_items_bill ON items(bill_id);');

    await db.execute('''
      CREATE TABLE bill_participants (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        contact_id TEXT NOT NULL,
        note TEXT,
        UNIQUE(bill_id, contact_id),
        FOREIGN KEY(bill_id) REFERENCES bills(id) ON DELETE CASCADE,
        FOREIGN KEY(contact_id) REFERENCES contacts(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
        'CREATE INDEX idx_participants_bill ON bill_participants(bill_id);');

    await db.execute('''
      CREATE TABLE item_shares (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        weight REAL NOT NULL,
        UNIQUE(item_id, participant_id),
        FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE,
        FOREIGN KEY(participant_id) REFERENCES bill_participants(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_shares_item ON item_shares(item_id);');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  Future<void> close() => db.close();
}

/// Compact, sortable, collision-resistant string id.
///
/// Format: `<base36 millis>_<8 random base36 chars>`. Not as sturdy as a
/// real cuid, but plenty for a single-device data set.
String newId() {
  final rnd = Random.secure();
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final chars =
      List.generate(8, (_) => rnd.nextInt(36).toRadixString(36)).join();
  return '${ts}_$chars';
}
