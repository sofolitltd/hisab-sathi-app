part of 'store.dart';

/// যোগাযোগের ইতিহাস (কল/মেসেজ/তাগাদা)।
extension StoreLogs on Store {
  Future<List<ContactLog>> logsOf(int customerId) async {
    final rows = await _db.query(
      'contact_logs',
      where: 'customer_id = ? AND deleted = 0',
      whereArgs: [customerId],
      orderBy: 'at DESC, id DESC',
    );
    return rows.map(ContactLog.fromMap).toList();
  }

  /// নতুন রেকর্ড; id ফেরত দেয় (পরে নোট যোগ করার জন্য)।
  Future<int> addLog(
    int customerId,
    ContactKind kind, {
    String note = '',
    DateTime? at,
  }) async {
    final customerUid = (await _db.query(
      'customers',
      columns: ['uid'],
      where: 'id = ?',
      whereArgs: [customerId],
    )).first['uid'];
    final id = await _db.insert(
      'contact_logs',
      _touch({
        'uid': Store.newUid(),
        'customer_id': customerId,
        'customer_uid': customerUid,
        'kind': kind.name,
        'note': note.trim(),
        'at': (at ?? DateTime.now()).millisecondsSinceEpoch,
      }),
    );
    logsChanged.value++;
    onLocalChange?.call();
    return id;
  }

  Future<void> updateLog(
    int id, {
    required ContactKind kind,
    required String note,
    required DateTime at,
  }) async {
    await _db.update(
      'contact_logs',
      _touch({
        'kind': kind.name,
        'note': note.trim(),
        'at': at.millisecondsSinceEpoch,
      }),
      where: 'id = ?',
      whereArgs: [id],
    );
    logsChanged.value++;
    onLocalChange?.call();
  }

  Future<void> deleteLog(int id) async {
    await _db.update(
      'contact_logs',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [id],
    );
    logsChanged.value++;
    onLocalChange?.call();
  }
}
