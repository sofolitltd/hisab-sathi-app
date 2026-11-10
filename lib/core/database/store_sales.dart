part of 'store.dart';

/// বিক্রয় — সেভের সময় প্রোডাক্টের দাম স্ন্যাপশট নেওয়া হয়, আর বাকি থাকলে link করা
/// কাস্টমারের ledger-এ সাধারণ বাকি এন্ট্রি (`Entry(type: baki)`) যুক্ত হয়।
extension StoreSales on Store {
  Future<List<Sale>> salesBetween(DateTime from, DateTime to) async {
    final rows = await _db.query(
      'sales',
      where: 'deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Sale.fromMap).toList();
  }

  /// লাভ ক্যাশ-ভিত্তিক — [product] দিলে (receivedAmount - buyPrice*quantity),
  /// মানে যতটা টাকা আসলে হাতে এলো তার ভিত্তিতে, ক্যাটালগ sell price ধরে না।
  /// বাকি থাকা অংশ (কাস্টমারের ledger-এ যাওয়া) তাই এখনই লাভ হিসেবে ধরা হয় না —
  /// পরে আদায় হলেও এই সেলের লাভ এমনিতে আপডেট হবে না (সেটা তখন কাস্টমারের
  /// নিজের বাকি-পাওনার হিসাবে ধরা পড়ে, এই রিপোর্টে না)। [product] না দিলে
  /// (ফ্রি-টেক্সট নাম) buy price জানা থাকে না — তখন [manualProfit] দিলে সেটাই
  /// লাভ হিসেবে সেভ হয়, নইলে লাভ অজানা (null) থাকে ও রিপোর্টের SUM(profit)
  /// এটা বাদ দেয়। [discount] (ইচ্ছাকৃত ছাড়) ক্যাটালগ দাম থেকে বাদ যায় —
  /// এটা "বাকি" নয়, তাই কাস্টমারের ledger-এ যোগ হয় না; ছাড়ের পরেও যদি
  /// [customerId] দেওয়া থাকে ও বাকি থাকে, তখনই সেই কাস্টমারের ledger-এ বাকি
  /// এন্ট্রি হয়।
  Future<void> addSale({
    Product? product,
    required String productName,
    required double quantity,
    required double receivedAmount,
    double discount = 0,
    double? manualProfit,
    int? customerId,
    DateTime? date,
    String note = '',
  }) async {
    final qty = quantity > 0 ? quantity : 1.0;
    String customerUid = '';
    if (customerId != null) {
      customerUid =
          (await _db.query(
                'customers',
                columns: ['uid'],
                where: 'id = ?',
                whereArgs: [customerId],
              )).first['uid']
              as String;
    }
    final name = productName.trim().isEmpty ? 'আয়' : productName.trim();
    final unitSell = product?.sellPrice ?? ((receivedAmount + discount) / qty);
    final profit = product != null
        ? receivedAmount - product.buyPrice * qty
        : manualProfit;
    final saleDate = date ?? DateTime.now();
    await _db.insert(
      'sales',
      _touch({
        'uid': Store.newUid(),
        'product_id': product?.id,
        'product_uid': product?.uid ?? '',
        'product_name': product?.name ?? name,
        'unit_buy_price': product?.buyPrice ?? 0,
        'unit_sell_price': unitSell,
        'quantity': qty,
        'customer_id': customerId,
        'customer_uid': customerUid,
        'received_amount': receivedAmount,
        'discount': discount,
        'date': saleDate.millisecondsSinceEpoch,
        'note': note.trim(),
        'profit': profit,
      }),
    );
    final due = unitSell * qty - discount - receivedAmount;
    if (customerId != null && due > 0.009) {
      await addEntry(
        customerId: customerId,
        type: EntryType.baki,
        amount: due,
        date: saleDate,
        note: note.trim().isEmpty ? 'আয়: $name' : note.trim(),
      );
    }
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  /// আগের বিক্রয় এডিট — প্রোডাক্ট/কাস্টমার/নোট/সময়/পরিমাণ/টাকা বদলানো। সেভের সময়
  /// প্রথমবারের মতোই দাম ও লাভ স্ন্যাপশট নেওয়া হয়। মনে রাখা জরুরি: আগে কাস্টমারের
  /// ledger-এ যে বাকি এন্ট্রি তৈরি হয়েছিল (থাকলে), সেটা এখানে ছোঁয়া হয় না —
  /// এটা একটা আলাদা, স্বাধীন এন্ট্রি হিসেবেই থেকে যাবে।
  Future<void> updateSale(
    Sale s, {
    Product? product,
    required String productName,
    required double quantity,
    required double receivedAmount,
    double discount = 0,
    double? manualProfit,
    int? customerId,
    required DateTime date,
    String note = '',
  }) async {
    final qty = quantity > 0 ? quantity : 1.0;
    String customerUid = '';
    if (customerId != null) {
      customerUid =
          (await _db.query(
                'customers',
                columns: ['uid'],
                where: 'id = ?',
                whereArgs: [customerId],
              )).first['uid']
              as String;
    }
    final name = productName.trim().isEmpty ? 'আয়' : productName.trim();
    final unitSell = product?.sellPrice ?? ((receivedAmount + discount) / qty);
    final profit = product != null
        ? receivedAmount - product.buyPrice * qty
        : manualProfit;
    await _db.update(
      'sales',
      _touch({
        'product_id': product?.id,
        'product_uid': product?.uid ?? '',
        'product_name': product?.name ?? name,
        'unit_buy_price': product?.buyPrice ?? 0,
        'unit_sell_price': unitSell,
        'quantity': qty,
        'customer_id': customerId,
        'customer_uid': customerUid,
        'received_amount': receivedAmount,
        'discount': discount,
        'date': date.millisecondsSinceEpoch,
        'note': note.trim(),
        'profit': profit,
      }),
      where: 'id = ?',
      whereArgs: [s.id],
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  Future<void> deleteSale(Sale s) async {
    await _db.update(
      'sales',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [s.id],
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  /// [from]-[to] এর মধ্যে মোট বিক্রয়, লাভ, আর ক্রয়ে ব্যয়।
  Future<({double sales, double profit, double purchaseCost})> profitBetween(
    DateTime from,
    DateTime to,
  ) async {
    final s = await _db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(unit_sell_price * quantity - discount), 0) AS sales,
        COALESCE(SUM(profit), 0) AS profit
      FROM sales WHERE deleted = 0 AND date >= ? AND date <= ?
    ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    final p = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(unit_cost * quantity), 0) AS cost
      FROM purchases WHERE deleted = 0 AND date >= ? AND date <= ?
    ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return (
      sales: (s.first['sales'] as num).toDouble(),
      profit: (s.first['profit'] as num).toDouble(),
      purchaseCost: (p.first['cost'] as num).toDouble(),
    );
  }

  /// দিনভিত্তিক লাভ (রিপোর্ট চার্টের জন্য), সাম্প্রতিক [days] দিন।
  Future<List<(DateTime, double)>> dailyProfit(int days) async {
    final from = DateUtils.dateOnly(
      DateTime.now().subtract(Duration(days: days - 1)),
    );
    final rows = await _db.rawQuery(
      '''
      SELECT date, profit
      FROM sales WHERE deleted = 0 AND date >= ?
    ''',
      [from.millisecondsSinceEpoch],
    );
    final byDay = <DateTime, double>{};
    for (var i = 0; i < days; i++) {
      byDay[DateUtils.addDaysToDate(from, i)] = 0;
    }
    for (final r in rows) {
      final day = DateUtils.dateOnly(
        DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
      );
      byDay[day] = (byDay[day] ?? 0) + ((r['profit'] as num?) ?? 0).toDouble();
    }
    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [for (final e in sorted) (e.key, e.value)];
  }

  /// প্রোডাক্ট-ভিত্তিক বিক্রয়/লাভ ব্রেকডাউন, [from]-[to] এর মধ্যে।
  Future<List<({String name, double sales, double profit})>>
  productBreakdown(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      '''
      SELECT product_name,
        SUM(unit_sell_price * quantity - discount) AS sales,
        COALESCE(SUM(profit), 0) AS profit
      FROM sales WHERE deleted = 0 AND date >= ? AND date <= ?
      GROUP BY product_name ORDER BY profit DESC
    ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final r in rows)
        (
          name: r['product_name'] as String,
          sales: (r['sales'] as num).toDouble(),
          profit: (r['profit'] as num).toDouble(),
        ),
    ];
  }
}
