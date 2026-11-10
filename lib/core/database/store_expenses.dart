part of 'store.dart';

/// ক্যাটেগরি-ভিত্তিক সাধারণ ব্যয় — দোকান ভাড়া, খাবার, বাজার ইত্যাদি।
extension StoreExpenses on Store {
  Future<List<Expense>> expensesBetween(DateTime from, DateTime to) async {
    final rows = await _db.query(
      'expenses',
      where: 'deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> allExpenses() async {
    final rows = await _db.query(
      'expenses',
      where: 'deleted = 0',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<double> expenseTotalBetween(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
      'WHERE deleted = 0 AND date >= ? AND date <= ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return ((rows.first['total'] as num?) ?? 0).toDouble();
  }

  Future<double> expenseTotalAll() async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses WHERE deleted = 0',
    );
    return ((rows.first['total'] as num?) ?? 0).toDouble();
  }

  /// আগে ব্যবহার করা ক্যাটেগরিগুলো — সাজেশন চিপে দেখানোর জন্য, সাম্প্রতিক আগে।
  Future<List<String>> expenseCategories() async {
    final rows = await _db.rawQuery(
      'SELECT category, MAX(date) AS last_date FROM expenses '
      'WHERE deleted = 0 GROUP BY category ORDER BY last_date DESC',
    );
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    DateTime? date,
    String note = '',
  }) async {
    await _db.insert(
      'expenses',
      _touch({
        'uid': Store.newUid(),
        'category': category.trim(),
        'amount': amount,
        'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
        'note': note.trim(),
      }),
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  Future<void> updateExpense(
    Expense e, {
    required String category,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    await _db.update(
      'expenses',
      _touch({
        'category': category.trim(),
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'note': note.trim(),
      }),
      where: 'id = ?',
      whereArgs: [e.id],
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  Future<void> deleteExpense(Expense e) async {
    await _db.update(
      'expenses',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [e.id],
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }
}
