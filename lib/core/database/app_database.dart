import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Completer<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (_opening != null) return _opening!.future;

    final completer = Completer<Database>();
    _opening = completer;
    try {
      final db = await _open();
      _db = db;
      completer.complete(db);
      return db;
    } catch (e, st) {
      _opening = null;
      completer.completeError(e, st);
      rethrow;
    }
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'taller_master.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createV1(db);
        await _createShopAccount(db);
        await _createPayments(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createShopAccount(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE orders ADD COLUMN received_at TEXT',
          );
        }
        if (oldVersion < 4) {
          await _createPayments(db);
          // Backfill advance payments from existing orders
          final rows = await db.query('orders');
          for (final row in rows) {
            final advance = (row['advance_amount'] as num?)?.toDouble() ?? 0;
            if (advance > 0) {
              await db.insert('payments', {
                'id': 'mig_${row['id']}',
                'order_id': row['id'],
                'amount': advance,
                'type': 'advance',
                'paid_at': row['order_date'] ?? DateTime.now().toIso8601String(),
                'note': 'پرانا ایڈوانس',
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }
      },
    );
  }

  Future<void> _createPayments(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id)',
    );
  }

  Future<void> _createShopAccount(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_account (
        id TEXT PRIMARY KEY,
        shop_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        address TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE karigars (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        specialty TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        order_no INTEGER NOT NULL,
        customer_id TEXT NOT NULL,
        karigar_id TEXT,
        garment_type TEXT NOT NULL,
        status TEXT NOT NULL,
        order_date TEXT NOT NULL,
        delivery_date TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        advance_amount REAL NOT NULL DEFAULT 0,
        measurements TEXT,
        instructions TEXT,
        tag_ids TEXT,
        received_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX idx_orders_order_no ON orders(order_no)',
    );

    final now = DateTime.now().toIso8601String();
    await db.insert('tags', {
      'id': 'tag_urgent',
      'name': 'فوری',
      'color': 0xFFDC2626,
      'created_at': now,
    });
    await db.insert('tags', {
      'id': 'tag_vip',
      'name': 'VIP',
      'color': 0xFFD97706,
      'created_at': now,
    });
    await db.insert('tags', {
      'id': 'tag_alter',
      'name': 'الٹر',
      'color': 0xFF0F766E,
      'created_at': now,
    });
  }
}
