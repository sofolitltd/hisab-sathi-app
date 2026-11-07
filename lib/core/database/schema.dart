part of 'store.dart';

// ডাটাবেস টেবিল ও মাইগ্রেশন — পুরনো মাইগ্রেশন কখনো বদলানো যাবে না।

/// কল/মেসেজ/তাগাদার ইতিহাস (v6)।
Future<void> _createContactLogs(Database db) async {
  await db.execute('''
    CREATE TABLE contact_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
      customer_uid TEXT NOT NULL,
      kind TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute(
    'CREATE INDEX idx_contact_logs_customer ON contact_logs(customer_id)',
  );
}

/// পুরনো (v2) ডাটাবেসে সিঙ্ক-কলাম যোগ ও আগের ডাটায় uid বসানো।
Future<void> _addSyncColumns(Database db) async {
  for (final t in ['customers', 'entries']) {
    await db.execute("ALTER TABLE $t ADD COLUMN uid TEXT NOT NULL DEFAULT ''");
    await db.execute(
      'ALTER TABLE $t ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE $t ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE $t ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1',
    );
    await db.execute("UPDATE $t SET uid = lower(hex(randomblob(16)))");
    await db.execute('CREATE UNIQUE INDEX idx_${t}_uid ON $t(uid)');
  }
  await db.execute(
    "ALTER TABLE entries ADD COLUMN customer_uid TEXT NOT NULL DEFAULT ''",
  );
  await db.execute('UPDATE customers SET updated_at = created_at');
  await db.execute('''
    UPDATE entries SET updated_at = date,
      customer_uid = (SELECT uid FROM customers c WHERE c.id = entries.customer_id)
  ''');
}

/// v8: balance-এর sign-কে একমাত্র সত্য ধরা হয় এখন থেকে (positive = পাওনা) —
/// আগে `pabo`/`debo` প্রতিটা নিজের ভেতরে স্বাধীনভাবে "baki বাড়ায়, joma কমায়"
/// নিয়ম মানত, তাই `debo` মানুষদের balance পজিটিভ থাকত "কত দেনা" বোঝাতে।
/// নতুন সার্বজনীন কনভেনশনে সেটা negative হওয়া উচিত — তাই তাদের পুরনো সব
/// entry-র type একবার উল্টে দেওয়া হচ্ছে (baki<->joma), যাতে
/// sum(baki)-sum(joma) থেকে সরাসরি সঠিক sign বেরোয়। এরপর থেকে `ledger`
/// কলাম শুধু শূন্য-ব্যালেন্সের টাই-ব্রেকার — রানটাইমে আর কখনো entry rewrite
/// হবে না (দেখুন `Customer.direction`, `Store._afterChange`)।
Future<void> _unifyBalanceDirection(Database db) async {
  await db.rawUpdate(
    '''
    UPDATE entries SET type = CASE type WHEN 'baki' THEN 'joma' ELSE 'baki' END,
      updated_at = ?, dirty = 1
    WHERE deleted = 0 AND customer_id IN (
      SELECT id FROM customers WHERE ledger = 'debo'
    )
  ''',
    [DateTime.now().millisecondsSinceEpoch],
  );
}
