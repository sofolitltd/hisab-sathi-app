part of 'notifier.dart';

/// রোজকার দুই নোটিফিকেশন — সকালের সারাংশ আর দিনের শেষের হিসাব।
abstract final class DailyNotifier {
  // ---------- দিনের শেষের হিসাব ----------

  static const _recapBaseId = 910000;
  static const _kRecapTime = 'recap_time', _kRecapOn = 'recap_on';

  /// দোকান বন্ধের আগে, যাতে বাদ পড়া হিসাব তখনই লেখা যায়।
  static final recapTime = ValueNotifier(const TimeOfDay(hour: 22, minute: 0));
  static final recapOn = ValueNotifier(true);

  static Future<void> setRecap({TimeOfDay? time, bool? on}) async {
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      recapTime.value = time;
      await prefs.setInt(_kRecapTime, time.hour * 60 + time.minute);
    }
    if (on != null) {
      recapOn.value = on;
      await prefs.setBool(_kRecapOn, on);
    }
  }

  /// প্রতিদিন [recapTime]-এ সেদিনের হিসাব: কত বাকি দেওয়া হলো, কত আদায়,
  /// আর মোট কত বাকি রইল। কিছু না লিখলে লিখে রাখার তাগাদা।
  ///
  /// নোটিফিকেশনের লেখা আগে থেকে ঠিক করে রাখতে হয়, তাই প্রতিবার ডাটা
  /// বদলালেই আবার বানানো হয়। আগামী দিনগুলো তাই "কিছু লেখা হয়নি" দিয়ে
  /// শিডিউল থাকে — সেদিন কিছু লিখলেই বদলে যায়। রাত ১২টার পরের সময় হলে
  /// আগের দিনের হিসাব (দোকান তো তখনও সেই দিনেরই)।
  static Future<void> scheduleRecaps({
    required Map<DateTime, DayTotals> days,
    required double pabo,
    required double debo,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final t = recapTime.value;
    final afterMidnight = t.hour < 5;
    for (var i = 0; i < 8; i++) {
      await Notifier.cancel(_recapBaseId + i);
      if (!recapOn.value) continue;
      final day = DateTime(now.year, now.month, now.day - 1 + i);
      final at = DateTime(
        day.year,
        day.month,
        day.day + (afterMidnight ? 1 : 0),
        t.hour,
        t.minute,
      );
      if (at.isBefore(now)) continue;

      final totals = days[day] ?? const DayTotals({});
      final when = afterMidnight ? '${fmtShortDate(day)}-এর' : 'আজকের';
      final lines = <String>[
        for (final l in Ledger.values)
          if (totals.count(l) > 0) totals.describe(l),
        [
          'মোট পাওনা ${taka(pabo)}',
          if (debo >= 0.01) 'মোট দেনা ${taka(debo)}',
        ].join(' • '),
      ];
      final empty = totals.isEmpty;
      final title = empty
          ? '$when হিসাব এখনো লেখা হয়নি'
          : '$when হিসাব: ${bn(totals.total)}টি লেনদেন';
      final body = empty
          ? 'কাকে কত দিলেন, কার কাছ থেকে কত পেলেন — এখনই লিখে রাখুন।\n${lines.last}'
          : lines.join('\n');

      await Notifier._plugin.zonedSchedule(
        id: _recapBaseId + i,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        title: title,
        body: body,
        payload: 'report:${day.millisecondsSinceEpoch}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'night_recap',
            'দিনের শেষের হিসাব',
            channelDescription: 'প্রতিদিন কত দিলেন আর কত পেলেন',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: Notifier._mode,
      );
    }
  }

  static const _summaryBaseId = 900000;
  static const _kSummaryTime = 'summary_time';

  /// দৈনিক সারাংশের সময় — ডিফল্ট সকাল ১০টা, প্রোফাইল থেকে বদলানো যায়।
  static final summaryTime = ValueNotifier(defaultReminderTime);

  static Future<void> setSummaryTime(TimeOfDay t) async {
    summaryTime.value = t;
    await (await SharedPreferences.getInstance()).setInt(
      _kSummaryTime,
      t.hour * 60 + t.minute,
    );
  }

  /// আগামী ৭ দিনের প্রতিদিন [summaryTime]-এ সকালের সারাংশ — দোকানে এসেই
  /// এক নজরে দিনের কাজ: আজ কার কাছ থেকে কত আদায় (মেয়াদ পারসহ), গতকাল
  /// কী লেখা হলো ([days]-এ থাকলে), আর মোট কত বাকি। কারও তারিখ না থাকলেও
  /// আসে। ডাটা বদলালেই নতুন করে হিসাব হয়।
  static Future<void> scheduleDailySummaries(
    List<Customer> customers, {
    Map<DateTime, DayTotals> days = const {},
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    for (var i = 0; i < 8; i++) {
      await Notifier.cancel(_summaryBaseId + i);
      final day = DateTime(now.year, now.month, now.day + i);
      final t = summaryTime.value;
      final at = DateTime(day.year, day.month, day.day, t.hour, t.minute);
      if (at.isBefore(now)) continue;

      // দিনের দিন বা মেয়াদ পার হওয়া — খাতা অনুযায়ী আলাদা
      List<Customer> dueBy(Ledger l) => customers
          .where(
            (c) =>
                c.direction == l &&
                c.hasDue &&
                c.dueDate != null &&
                !DateUtils.dateOnly(c.dueDate!).isAfter(day),
          )
          .toList();
      final pabo = dueBy(Ledger.pabo);
      final debo = dueBy(Ledger.debo);

      double sum(Iterable<Customer> l) => l.fold(0, (s, c) => s + c.balance);
      String names(List<Customer> l) => l.map((c) => c.name).take(3).join(', ');
      Iterable<Customer> owing(Ledger l) =>
          customers.where((c) => c.direction == l && c.hasDue);
      final yesterday = days[DateTime(day.year, day.month, day.day - 1)];
      final lines = <String>[
        if (pabo.isNotEmpty)
          'আদায়: ${bn(pabo.length)} জনের কাছে ${taka(sum(pabo))} (${names(pabo)})',
        if (debo.isNotEmpty)
          'পরিশোধ: ${bn(debo.length)} জনকে ${taka(sum(debo))} (${names(debo)})',
        if (pabo.isEmpty && debo.isEmpty)
          'আজ কারও কাছ থেকে টাকা নেওয়ার তারিখ নেই।',
        if (yesterday != null)
          yesterday.isEmpty
              ? 'গতকাল কোনো হিসাব লেখা হয়নি।'
              : 'গতকাল — ${[for (final l in Ledger.values)
                  if (yesterday.count(l) > 0) yesterday.describe(l)].join(' | ')}',
        [
          'মোট পাওনা ${taka(sum(owing(Ledger.pabo)))} (${bn(owing(Ledger.pabo).length)} জন)',
          if (owing(Ledger.debo).isNotEmpty)
            'মোট দেনা ${taka(sum(owing(Ledger.debo)))}',
        ].join(' • '),
      ];
      final body = lines.join('\n');
      final title = pabo.isNotEmpty
          ? 'আজ আদায় করুন: ${taka(sum(pabo))}'
          : debo.isNotEmpty
          ? 'আজ পরিশোধ করুন: ${taka(sum(debo))}'
          : 'শুভ সকাল! আজকের খাতা';

      await Notifier._plugin.zonedSchedule(
        id: _summaryBaseId + i,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        title: title,
        body: body,
        payload: 'report:${day.millisecondsSinceEpoch}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary',
            'দৈনিক সারাংশ',
            channelDescription:
                'প্রতিদিন সকালে কার কাছ থেকে কত পাবেন আর কাকে কত দেবেন',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: Notifier._mode,
      );
    }
  }

  // ---------- বিক্রয়-ক্রয়-ব্যয়ের সারাংশ ----------

  static const _tradeBaseId = 920000;

  /// দিনের শেষের হিসাবের [recapTime]-এর ৫ মিনিট পরে — যাতে দুটো নোটিফিকেশন
  /// একসাথে গুলিয়ে না যায়। আলাদা কোনো সেটিং রাখা হয়নি, রিক্যাপের সময় বদলালে
  /// এটাও সেই অনুযায়ী বদলে যায়।
  static Future<void> scheduleTradeSummaries({
    required Map<DateTime, TradeTotals> days,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    final t = recapTime.value;
    final afterMidnight = t.hour < 5;
    for (var i = 0; i < 8; i++) {
      await Notifier.cancel(_tradeBaseId + i);
      if (!recapOn.value) continue;
      final day = DateTime(now.year, now.month, now.day - 1 + i);
      final at = DateTime(
        day.year,
        day.month,
        day.day + (afterMidnight ? 1 : 0),
        t.hour,
        t.minute + 5,
      );
      if (at.isBefore(now)) continue;

      final trade = days[day] ?? const TradeTotals();
      if (trade.isEmpty) continue;
      final when = afterMidnight ? '${fmtShortDate(day)}-এর' : 'আজকের';
      final lines = <String>[
        'বিক্রয় ${taka(trade.sales)}',
        if (trade.purchaseCost >= 0.01) 'ক্রয় ${taka(trade.purchaseCost)}',
        if (trade.expense >= 0.01) 'ব্যয় ${taka(trade.expense)}',
        'লাভ ${taka(trade.profit - trade.expense)}',
      ];

      await Notifier._plugin.zonedSchedule(
        id: _tradeBaseId + i,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        title: '$when ব্যবসার সারাংশ',
        body: lines.join(' • '),
        payload: 'report:${day.millisecondsSinceEpoch}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'trade_summary',
            'বিক্রয়-ক্রয়ের সারাংশ',
            channelDescription: 'প্রতিদিন রাতে বিক্রয়, ক্রয় আর ব্যয়ের হিসাব',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(lines.join('\n')),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: Notifier._mode,
      );
    }
  }
}

/// একদিনের বিক্রয়-ক্রয়-ব্যয়ের সারাংশ।
class TradeTotals {
  const TradeTotals({
    this.sales = 0,
    this.profit = 0,
    this.purchaseCost = 0,
    this.expense = 0,
  });
  final double sales;
  final double profit;
  final double purchaseCost;
  final double expense;

  bool get isEmpty => sales == 0 && purchaseCost == 0 && expense == 0;
}

/// একদিনের লেনদেন — খাতা ও ধরন অনুযায়ী (মোট টাকা, কতটা এন্ট্রি)।
class DayTotals {
  const DayTotals(this._m);
  final Map<(Ledger, EntryType), (double, int)> _m;

  (double, int) of(Ledger l, EntryType t) => _m[(l, t)] ?? (0, 0);

  int count(Ledger l) => of(l, EntryType.baki).$2 + of(l, EntryType.joma).$2;
  int get total => Ledger.values.fold(0, (n, l) => n + count(l));
  bool get isEmpty => total == 0;

  /// "পাওনা: বাকি দেওয়া ৳৫০০ (২টি), আদায় হয়েছে ৳২০০ (১টি)"
  String describe(Ledger l) {
    final t = LedgerText.of(l);
    final (add, an) = of(l, l.grows);
    final (red, rn) = of(l, l.shrinks);
    return '${t.name}: ${[if (an > 0) '${t.added} ${taka(add)} (${bn(an)}টি)', if (rn > 0) '${t.reduced} ${taka(red)} (${bn(rn)}টি)'].join(', ')}';
  }
}
