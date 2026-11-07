import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/notifications/notifier.dart';
import 'package:dena_pawna/core/photo/photo.dart';
import 'package:dena_pawna/core/utils/utils.dart';

part 'schema.dart';
part 'store_customers.dart';
part 'store_entries.dart';
part 'store_logs.dart';
part 'store_schedule.dart';
part 'store_stats.dart';
part 'store_sync.dart';

/// অ্যাপের সব ডাটা (লোকাল SQLite) — একটাই জায়গা থেকে পড়া/লেখা হয়।
///
/// অফলাইন-ফার্স্ট: সব কাজ আগে লোকাল ডাটাবেসে হয়। পরে অনলাইন সিঙ্ক যোগ করার
/// জন্য প্রতিটা রেকর্ডে আছে —
///   uid        : সব ডিভাইসে একই থাকা স্থায়ী আইডি (লোকাল `id` শুধু এই ফোনের)
///   updated_at : শেষ পরিবর্তনের সময় (সিঙ্কে কোনটা নতুন তা বোঝার জন্য)
///   deleted    : মুছলে সাথে সাথে না মুছে চিহ্ন দেওয়া, যাতে সার্ভারেও মোছা যায়
///   dirty      : ১ = সার্ভারে এখনো পাঠানো হয়নি
class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();

  late Database _db;

  /// সবার তালিকা — কোনো মোড দিয়ে ফিল্টার হয় না, যার যার direction তার
  /// balance-এর sign থেকে লাইভ গণনা হয়।
  List<Customer> all = [];
  bool loaded = false;

  /// আগের নাম ধরে রাখা হলো কম জায়গায় বদলাতে হয় — আসলে সবাই।
  List<Customer> get customers => all;

  /// [l] খাতার মোট — balance ঋণাত্মক হতে পারে (payable দিক), তাই abs() ব্যবহার।
  double totalOf(Ledger l) => all.fold(
    0,
    (s, c) => c.direction == l && c.hasDue ? s + c.balance.abs() : s,
  );

  static final _rand = Random.secure();
  static String newUid() => List.generate(
    16,
    (_) => _rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  /// লোকাল ডাটা বদলালে সিঙ্ক সার্ভিসকে জানানোর হুক।
  VoidCallback? onLocalChange;

  /// ইতিহাস বদলালে বাড়ে — খোলা পাতাগুলো আবার পড়ে নেয়।
  final logsChanged = ValueNotifier(0);

  Future<void> init() async {
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    _db = await openDatabase(
      kIsWeb
          ? 'baki_khata.db'
          : p.join(await getDatabasesPath(), 'baki_khata.db'),
      version: 8,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE customers ADD COLUMN photo TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) await _addSyncColumns(db);
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE customers ADD COLUMN ledger TEXT NOT NULL DEFAULT 'pabo'",
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE customers ADD COLUMN extra_phones TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 6) await _createContactLogs(db);
        if (oldVersion < 7) {
          await db.execute(
            "ALTER TABLE customers ADD COLUMN plan TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 8) await _unifyBalanceDirection(db);
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL UNIQUE,
            ledger TEXT NOT NULL DEFAULT 'pabo',
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            extra_phones TEXT NOT NULL DEFAULT '',
            plan TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            photo TEXT NOT NULL DEFAULT '',
            due_date INTEGER,
            reminder_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        await db.execute('''
          CREATE TABLE entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uid TEXT NOT NULL UNIQUE,
            customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
            customer_uid TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            date INTEGER NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            updated_at INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            dirty INTEGER NOT NULL DEFAULT 1
          )''');
        await db.execute(
          'CREATE INDEX idx_entries_customer ON entries(customer_id)',
        );
        await _createContactLogs(db);
      },
    );
    await refresh();
  }

  Future<void> refresh() async {
    final rows = await _db.rawQuery('''
      SELECT c.*,
        COALESCE(SUM(CASE WHEN e.type = 'baki' THEN e.amount ELSE -e.amount END), 0) AS balance,
        MAX(e.date) AS last_entry_at,
        MAX(CASE WHEN e.type = 'baki' THEN e.date END) AS last_baki_at,
        MAX(CASE WHEN e.type = 'joma' THEN e.date END) AS last_joma_at
      FROM customers c
      LEFT JOIN entries e ON e.customer_id = c.id AND e.deleted = 0
      WHERE c.deleted = 0
      GROUP BY c.id
    ''');
    all = (await _withPlanPaid(rows)).map(Customer.fromMap).toList();
    loaded = true;
    notifyListeners();
    scheduleDaily();
  }

  Customer? byId(int id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

int _now() => DateTime.now().millisecondsSinceEpoch;

/// পরিবর্তিত রেকর্ডে সিঙ্ক-ফিল্ড বসানো।
Map<String, Object?> _touch(Map<String, Object?> values) => {
  ...values,
  'updated_at': _now(),
  'dirty': 1,
};
