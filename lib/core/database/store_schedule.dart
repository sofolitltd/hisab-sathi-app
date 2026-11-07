part of 'store.dart';

/// কিস্তি, "কবে দেবে" তারিখ ও রিমাইন্ডারের হিসাব।
extension StoreSchedule on Store {
  /// কিস্তি চলছে এমন ব্যক্তিদের, পরিকল্পনার দিন থেকে মোট শোধ যোগ করে — পাওনায়
  /// পেলামগুলো, দেনায় দিলামগুলো।
  Future<List<Map<String, Object?>>> _withPlanPaid(
    List<Map<String, Object?>> rows,
  ) async {
    final plans = <int, InstallmentPlan>{};
    final shrinks = <int, String>{};
    for (final r in rows) {
      final p = InstallmentPlan.decode(r['plan'] as String?);
      if (p == null) continue;
      final id = r['id'] as int;
      plans[id] = p;
      shrinks[id] = ((r['balance'] as num?) ?? 0) < 0 ? 'baki' : 'joma';
    }
    if (plans.isEmpty) return rows;
    final entries = await _db.query(
      'entries',
      columns: ['customer_id', 'type', 'amount', 'date'],
      where:
          'deleted = 0 AND customer_id IN '
          '(${List.filled(plans.length, '?').join(',')})',
      whereArgs: plans.keys.toList(),
    );
    final paid = <int, double>{};
    for (final e in entries) {
      final id = e['customer_id'] as int;
      if (e['type'] != shrinks[id]) continue;
      final from = plans[id]!.from;
      final day = DateTime(from.year, from.month, from.day);
      if ((e['date'] as int) >= day.millisecondsSinceEpoch) {
        paid[id] = (paid[id] ?? 0) + (e['amount'] as num).toDouble();
      }
    }
    return [
      for (final r in rows)
        paid.containsKey(r['id']) ? {...r, 'plan_paid': paid[r['id']]} : r,
    ];
  }

  /// কিস্তির পরিকল্পনা বসানো বা (null দিলে) বন্ধ করা।
  Future<void> setPlan(int id, InstallmentPlan? plan) async {
    await _db.update(
      'customers',
      _touch({'plan': plan?.encode() ?? ''}),
      where: 'id = ?',
      whereArgs: [id],
    );
    await _afterChange(id);
  }

  /// যেকোনো পরিবর্তনের পর: হিসাব রিফ্রেশ (খাতা/দিক সবসময় balance থেকে লাইভ
  /// গণনা হয়, তাই এখানে আলাদা করে কিছু মুভ/mutate করতে হয় না), বাকি শোধ হলে
  /// তারিখ/রিমাইন্ডার মুছে ফেলা, আর রিমাইন্ডার নোটিফিকেশন নতুন করে সেট করা।
  Future<void> _afterChange(int id) async {
    final prev = byId(id);
    onLocalChange?.call();
    await refresh();
    final c = byId(id);
    if (c == null) return;
    final flipped =
        prev != null &&
        prev.hasDue &&
        c.hasDue &&
        prev.direction != c.direction;
    final hasSchedule =
        c.dueDate != null || c.reminderAt != null || c.plan != null;
    if (!c.hasDue && hasSchedule) {
      await _clearSchedule(id);
    } else if (flipped && hasSchedule) {
      // পাওনা ⇄ দেনা উল্টালে "কবে দেবে" তারিখ আর কিস্তির মানেও উল্টে যায়
      await _clearSchedule(id);
      await addLog(
        id,
        ContactKind.note,
        note:
            'হিসাব ${LedgerText.of(prev.direction).name} থেকে '
            '${LedgerText.of(c.direction).name} হয়ে গেছে — '
            'আগের তারিখ, রিমাইন্ডার ও কিস্তি বন্ধ',
      );
    } else if (c.onPlan) {
      await _followPlan(c);
    }
    await Notifier.schedule(byId(id)!);
  }

  Future<void> _clearSchedule(int id) async {
    await _db.update(
      'customers',
      _touch({'due_date': null, 'reminder_at': null, 'plan': ''}),
      where: 'id = ?',
      whereArgs: [id],
    );
    await refresh();
  }

  /// কিস্তি চললে চলতি কিস্তির তারিখটাই "কবে দেবে" আর রিমাইন্ডার — তাই
  /// জমা লিখলে পরের কিস্তির তারিখ নিজে থেকে বসে। রিমাইন্ডারের সময় আগেরটাই,
  /// না থাকলে সকাল ১০টা।
  Future<void> _followPlan(Customer c) async {
    final next = c.planStatus!.nextDate;
    final old = c.dueDate;
    if (old != null &&
        old.year == next.year &&
        old.month == next.month &&
        old.day == next.day) {
      return;
    }
    final t = c.reminderAt;
    final at = DateTime(
      next.year,
      next.month,
      next.day,
      t?.hour ?? 10,
      t?.minute ?? 0,
    );
    // কিস্তির দিনের সময় পার হয়ে গেলে বাদ না দিয়ে পরদিন একই সময়ে
    final now = DateTime.now();
    final remind = at.isAfter(now)
        ? at
        : DateTime(now.year, now.month, now.day + 1, at.hour, at.minute);
    await _setSchedule(c.id, next, remind);
    await refresh();
  }
}
