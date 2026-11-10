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

/// ক্রয়-বিক্রয় (v9): প্রোডাক্ট, বিক্রয়, ক্রয়।
Future<void> _createPurchaseSaleTables(Database db) async {
  await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      buy_price REAL NOT NULL DEFAULT 0,
      sell_price REAL NOT NULL DEFAULT 0,
      unit TEXT NOT NULL DEFAULT 'piece',
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      product_id INTEGER REFERENCES products(id),
      product_uid TEXT NOT NULL DEFAULT '',
      product_name TEXT NOT NULL DEFAULT '',
      unit_buy_price REAL NOT NULL DEFAULT 0,
      unit_sell_price REAL NOT NULL DEFAULT 0,
      quantity REAL NOT NULL DEFAULT 1,
      customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
      customer_uid TEXT NOT NULL DEFAULT '',
      received_amount REAL NOT NULL DEFAULT 0,
      date INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      profit REAL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute('CREATE INDEX idx_sales_product ON sales(product_id)');
  await db.execute('CREATE INDEX idx_sales_customer ON sales(customer_id)');
  await db.execute('''
    CREATE TABLE purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      product_id INTEGER NOT NULL REFERENCES products(id),
      product_uid TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 1,
      unit_cost REAL NOT NULL DEFAULT 0,
      date INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute(
    'CREATE INDEX idx_purchases_product ON purchases(product_id)',
  );
}

/// v10: sales.product_id আগে NOT NULL ছিল, কিন্তু প্রোডাক্ট ছাড়া (ফ্রি-টেক্সট
/// নাম) বিক্রয় সেভ করা যাচ্ছে এখন — SQLite-এ কলামের NOT NULL সরাসরি বদলানো যায়
/// না, তাই টেবিল পুনরায় তৈরি করে ডাটা কপি করা হচ্ছে।
Future<void> _allowSaleWithoutProduct(Database db) async {
  await db.execute('ALTER TABLE sales RENAME TO sales_old');
  await db.execute('''
    CREATE TABLE sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      product_id INTEGER REFERENCES products(id),
      product_uid TEXT NOT NULL DEFAULT '',
      product_name TEXT NOT NULL DEFAULT '',
      unit_buy_price REAL NOT NULL DEFAULT 0,
      unit_sell_price REAL NOT NULL DEFAULT 0,
      quantity REAL NOT NULL DEFAULT 1,
      customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
      customer_uid TEXT NOT NULL DEFAULT '',
      received_amount REAL NOT NULL DEFAULT 0,
      date INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute('INSERT INTO sales SELECT * FROM sales_old');
  await db.execute('DROP TABLE sales_old');
  await db.execute('CREATE INDEX idx_sales_product ON sales(product_id)');
  await db.execute('CREATE INDEX idx_sales_customer ON sales(customer_id)');
}

/// v11: লাভ এখন সরাসরি একটা কলামে রাখা হয় (NULL = অজানা) — প্রোডাক্ট লিংক করা
/// থাকলে (sell-buy)*quantity, নইলে ব্যবহারকারীর হাতে লেখা লাভ (দিলে), নইলে NULL।
/// রিপোর্টের SUM(profit) স্বয়ংক্রিয়ভাবে NULL বাদ দেয়, তাই আলাদা করে
/// product_id চেক লাগে না।
Future<void> _addSalesProfitColumn(Database db) async {
  await db.execute('ALTER TABLE sales ADD COLUMN profit REAL');
}

/// v12: products.unit কলামটা v9-এর টেবিল-তৈরির কোডেই (ভুলভাবে) যোগ করা
/// হয়েছিল, যে ডিভাইস তখনই v9-এ ছিল (table তৈরি হয়ে গেছে) তাদের কলামটা মিস।
/// table_info চেক করে নেওয়া হচ্ছে — যাদের fresh install-এ অলরেডি আছে, তাদের
/// আবার ALTER করতে গেলে "duplicate column" এরর হতো।
Future<void> _addProductsUnitColumn(Database db) async {
  final cols = await db.rawQuery('PRAGMA table_info(products)');
  final hasUnit = cols.any((c) => c['name'] == 'unit');
  if (!hasUnit) {
    await db.execute(
      "ALTER TABLE products ADD COLUMN unit TEXT NOT NULL DEFAULT 'piece'",
    );
  }
}

/// v13: বিক্রয়ে ইচ্ছাকৃত ছাড় (discount) আলাদাভাবে রাখা — আগে ক্যাটালগ দামের
/// চেয়ে কম টাকা পেলে পুরোটাই "বাকি" ধরে কাস্টমারের ledger-এ যুক্ত হয়ে যেত,
/// যদিও সেটা অনেক সময় আসলে দেওয়া ছাড়, আদায় করার বাকি নয়। [onCreate]-ও
/// `_createPurchaseSaleTables`-এর ওপর নির্ভর করে বলে ফ্রেশ ইনস্টলেও এই
/// কলাম লাগবে — তাই দুই জায়গা থেকেই ডাকা হয়, "duplicate column" এড়াতে চেক।
Future<void> _addSalesDiscountColumn(Database db) async {
  final cols = await db.rawQuery('PRAGMA table_info(sales)');
  final hasDiscount = cols.any((c) => c['name'] == 'discount');
  if (!hasDiscount) {
    await db.execute(
      'ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0',
    );
  }
}

/// v14: ক্যাটেগরি-ভিত্তিক সাধারণ ব্যয় (দোকান ভাড়া, খাবার, বাজার ইত্যাদি) —
/// প্রোডাক্ট ক্রয়ের (purchases) সাথে সম্পর্কহীন, স্বাধীন টেবিল।
Future<void> _createExpensesTable(Database db) async {
  await db.execute('''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      uid TEXT NOT NULL UNIQUE,
      category TEXT NOT NULL,
      amount REAL NOT NULL DEFAULT 0,
      date INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0,
      dirty INTEGER NOT NULL DEFAULT 1
    )''');
  await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
}
