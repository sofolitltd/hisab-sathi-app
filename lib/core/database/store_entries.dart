part of 'store.dart';

/// বাকি/জমা লেখা, বদলানো, মোছা ও তারিখ সেট।
extension StoreEntries on Store {
  /// বাকি বা জমা যোগ করা। বাকির সাথে "কবে দেবে" ও রিমাইন্ডার সেট হয়।
  Future<void> addEntry({
    required int customerId,
    required EntryType type,
    required double amount,
    DateTime? date,
    String note = '',
    DateTime? dueDate,
    DateTime? reminderAt,
    bool updateSchedule = false,
  }) async {
    final customerUid = (await _db.query(
      'customers',
      columns: ['uid'],
      where: 'id = ?',
      whereArgs: [customerId],
    )).first['uid'];
    await _db.insert(
      'entries',
      _touch({
        'uid': Store.newUid(),
        'customer_id': customerId,
        'customer_uid': customerUid,
        'type': type.name,
        'amount': amount,
        'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
        'note': note.trim(),
      }),
    );
    if (updateSchedule) {
      await _logDueChange(customerId, dueDate);
      await _setSchedule(customerId, dueDate, reminderAt);
    }
    await _afterChange(customerId);
  }

  Future<void> updateEntry(
    Entry e, {
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    await _db.update(
      'entries',
      _touch({
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'note': note.trim(),
      }),
      where: 'id = ?',
      whereArgs: [e.id],
    );
    await _afterChange(e.customerId);
  }

  Future<void> deleteEntry(Entry e) async {
    await _db.update(
      'entries',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [e.id],
    );
    await _afterChange(e.customerId);
  }

  Future<void> setSchedule(
    int customerId,
    DateTime? dueDate,
    DateTime? reminderAt,
  ) async {
    await _logDueChange(customerId, dueDate);
    await _setSchedule(customerId, dueDate, reminderAt);
    await _afterChange(customerId);
  }

  /// ব্যবহারকারী আগের তারিখ বদলে নতুন দিলে ইতিহাসে লিখে রাখে। কিস্তি বা শোধের
  /// কারণে অ্যাপ নিজে তারিখ বদলালে (_setSchedule সরাসরি) লেখা হয় না।
  Future<void> _logDueChange(int id, DateTime? due) async {
    final old = byId(id)?.dueDate;
    if (old == null || due == null || DateUtils.isSameDay(old, due)) return;
    await addLog(
      id,
      ContactKind.due,
      note: 'তারিখ: ${fmtDate(old)} → ${fmtDate(due)}',
    );
  }

  Future<void> _setSchedule(int id, DateTime? due, DateTime? reminder) =>
      _db.update(
        'customers',
        _touch({
          'due_date': due?.millisecondsSinceEpoch,
          'reminder_at': reminder?.millisecondsSinceEpoch,
        }),
        where: 'id = ?',
        whereArgs: [id],
      );

  /// সব কাস্টমারের সাম্প্রতিক লেনদেন (নামসহ), দুই দিক মিলিয়ে।
  Future<List<(Entry, String)>> recentEntries(int limit) async {
    final rows = await _db.rawQuery(
      '''
      SELECT e.*, c.name AS customer_name FROM entries e
      JOIN customers c ON c.id = e.customer_id
      WHERE e.deleted = 0 AND c.deleted = 0
      ORDER BY e.date DESC, e.id DESC LIMIT ?
    ''',
      [limit],
    );
    return [
      for (final r in rows) (Entry.fromMap(r), r['customer_name'] as String),
    ];
  }
}
