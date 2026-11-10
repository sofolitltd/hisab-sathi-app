part of 'store.dart';

/// পরিসংখ্যান ও রোজকার নোটিফিকেশন।
extension StoreStats on Store {
  /// সব কাস্টমারের রিমাইন্ডার আর রোজকার নোটিফিকেশন আবার বসানো
  /// (যেমন ঠিক সময়ের অনুমতি পাওয়ার পর)।
  Future<void> rescheduleAll() async {
    for (final c in all) {
      await Notifier.schedule(c);
    }
    await scheduleDaily();
  }

  /// সকালের সারাংশ আর দিনের শেষের হিসাব — দুটো রোজকার নোটিফিকেশন নতুন
  /// করে বানায় (গতকাল ও আজকের লেনদেনসহ)।
  Future<void> scheduleDaily() async {
    final now = DateTime.now();
    final days = [
      DateTime(now.year, now.month, now.day - 1),
      DateTime(now.year, now.month, now.day),
    ];
    final totals = {for (final d in days) d: await dayTotals(d)};
    final trade = {for (final d in days) d: await tradeTotals(d)};
    await DailyNotifier.scheduleDailySummaries(all, days: totals);
    await DailyNotifier.scheduleRecaps(
      days: totals,
      pabo: totalOf(Ledger.pabo),
      debo: totalOf(Ledger.debo),
    );
    await DailyNotifier.scheduleTradeSummaries(days: trade);
  }

  /// একদিনের বিক্রয়-ক্রয়-ব্যয়ের সারাংশ (রাতের নোটিফিকেশন ও রিপোর্ট পাতার জন্য)।
  Future<TradeTotals> tradeTotals(DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    final p = await profitBetween(from, to);
    final expense = await expenseTotalBetween(from, to);
    return TradeTotals(
      sales: p.sales,
      profit: p.profit,
      purchaseCost: p.purchaseCost,
      expense: expense,
    );
  }

  /// একদিনের লেনদেন, দুই খাতা মিলিয়ে। direction DB কলাম না (balance থেকে
  /// লাইভ গণনা হয়), তাই customer_id ধরে এনে Dart-এ (direction, type) অনুযায়ী
  /// যোগ করা হয় — SQL-এ সরাসরি `GROUP BY` করা যায় না।
  Future<DayTotals> dayTotals(DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final rows = await _db.rawQuery(
      '''
      SELECT e.customer_id, e.type, SUM(e.amount) AS total, COUNT(*) AS n FROM entries e
      JOIN customers c ON c.id = e.customer_id
      WHERE e.deleted = 0 AND c.deleted = 0 AND e.date >= ? AND e.date < ?
      GROUP BY e.customer_id, e.type
    ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    final acc = <(Ledger, EntryType), (double, int)>{};
    for (final r in rows) {
      final c = byId(r['customer_id'] as int);
      if (c == null) continue;
      final key = (
        c.direction,
        r['type'] == 'joma' ? EntryType.joma : EntryType.baki,
      );
      final prev = acc[key] ?? (0.0, 0);
      acc[key] = (
        prev.$1 + (r['total'] as num).toDouble(),
        prev.$2 + (r['n'] as int),
      );
    }
    return DayTotals(acc);
  }

  /// নির্দিষ্ট সময়ের মধ্যে মোট দিলাম (baki) ও পেলাম (joma), সবাই মিলিয়ে।
  /// [ledger] দিলে শুধু এখন সেই দিকের লোকেরা, আর তখন baki = সেই দিকের হিসাব
  /// বাড়া, joma = কমা — দেনায় তাই পেলাম/দিলাম অদলবদল হয়ে আসে।
  Future<({double baki, double joma, int count})> totalsBetween(
    DateTime? from,
    DateTime? to, [
    Ledger? ledger,
  ]) async {
    final ids = ledger == null
        ? null
        : [
            for (final c in all)
              if (c.direction == ledger) c.id,
          ];
    if (ids != null && ids.isEmpty) return (baki: 0.0, joma: 0.0, count: 0);
    final rows = await _db.rawQuery(
      '''
      SELECT e.type, SUM(e.amount) AS total, COUNT(*) AS n FROM entries e
      JOIN customers c ON c.id = e.customer_id
      WHERE e.deleted = 0 AND c.deleted = 0
        AND e.date >= ? AND e.date < ?
        ${ids == null ? '' : 'AND e.customer_id IN (${List.filled(ids.length, '?').join(',')})'}
      GROUP BY e.type
    ''',
      [
        from?.millisecondsSinceEpoch ?? 0,
        to?.millisecondsSinceEpoch ?? 8640000000000000,
        ...?ids,
      ],
    );
    final grows = ledger == Ledger.debo ? 'joma' : 'baki';
    var baki = 0.0, joma = 0.0, n = 0;
    for (final r in rows) {
      final t = (r['total'] as num).toDouble();
      if (r['type'] == grows) {
        baki = t;
      } else {
        joma = t;
      }
      n += r['n'] as int;
    }
    return (baki: baki, joma: joma, count: n);
  }

  /// গত [months] মাসের মাসভিত্তিক বাকি ও আদায়।
  Future<List<({DateTime month, double baki, double joma})>> monthly(
    int months, [
    Ledger? ledger,
  ]) async {
    final now = DateTime.now();
    final out = <({DateTime month, double baki, double joma})>[];
    for (var i = months - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i);
      final end = DateTime(now.year, now.month - i + 1);
      final t = await totalsBetween(start, end, ledger);
      out.add((month: start, baki: t.baki, joma: t.joma));
    }
    return out;
  }
}
