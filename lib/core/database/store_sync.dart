part of 'store.dart';

/// অনলাইন সিঙ্কের জন্য dirty রেকর্ড পড়া ও সার্ভারের ডাটা মেশানো।
extension StoreSync on Store {
  /// সার্ভারে পাঠানো বাকি আছে এমন রেকর্ডের সংখ্যা (সিঙ্ক চালু হলে কাজে লাগবে)।
  Future<int> pendingSyncCount() async {
    final r = await _db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM customers WHERE dirty = 1) + '
      '(SELECT COUNT(*) FROM entries WHERE dirty = 1) + '
      '(SELECT COUNT(*) FROM contact_logs WHERE dirty = 1) AS n',
    );
    return r.first['n'] as int;
  }

  /// সার্ভারে পাঠানো বাকি রেকর্ডগুলো।
  Future<
    ({
      List<Map<String, Object?>> customers,
      List<Map<String, Object?>> entries,
      List<Map<String, Object?>> logs,
    })
  >
  dirtyRows() async => (
    customers: await _db.query('customers', where: 'dirty = 1'),
    entries: await _db.query('entries', where: 'dirty = 1'),
    logs: await _db.query('contact_logs', where: 'dirty = 1'),
  );

  /// পাঠানো রেকর্ড "পরিষ্কার" চিহ্নিত করা। পাঠানোর মাঝে বদলে গেলে (updated_at ভিন্ন)
  /// dirty-ই থেকে যায়, পরের সিঙ্কে আবার যায়।
  Future<void> markPushed(String table, List<Map<String, Object?>> rows) async {
    final b = _db.batch();
    for (final r in rows) {
      b.update(
        table,
        {'dirty': 0},
        where: 'uid = ? AND updated_at = ?',
        whereArgs: [r['uid'], r['updated_at']],
      );
    }
    await b.commit(noResult: true);
  }

  /// নতুন অ্যাকাউন্টে ঢুকলে এই ফোনের সব ডাটা আবার পাঠানোর জন্য।
  Future<void> markAllDirty() async {
    await _db.update('customers', {'dirty': 1});
    await _db.update('entries', {'dirty': 1});
    await _db.update('contact_logs', {'dirty': 1});
  }

  /// সার্ভার থেকে আসা পরিবর্তন মেশানো। লোকালে নতুন কিছু থাকলে সেটাই থাকে।
  /// সার্ভারের ছবি (data URI) লোকাল ফাইলে সেভ হয়।
  Future<void> applyRemote(
    List customers,
    List entries, [
    List logs = const [],
  ]) async {
    if (customers.isEmpty && entries.isEmpty && logs.isEmpty) return;
    final changed = <int>{};
    final removed = <int>{};
    // ছবি ফাইলে লিখতে হয় বলে ট্রানজ্যাকশনের আগেই করে রাখা।
    final photos = <Map<String, dynamic>, String>{};
    for (final m in customers.cast<Map<String, dynamic>>()) {
      photos[m] = await photoFromData((m['photo'] as String?) ?? '');
    }
    final stale = <String>[];
    await _db.transaction((txn) async {
      for (final m in customers.cast<Map<String, dynamic>>()) {
        final local = (await txn.query(
          'customers',
          columns: ['id', 'updated_at', 'photo', 'extra_phones', 'plan'],
          where: 'uid = ?',
          whereArgs: [m['uid']],
        )).firstOrNull;
        final values = {
          'ledger': m['ledger'],
          'name': m['name'],
          'phone': m['phone'],
          // পুরোনো সার্ভার এই ঘর পাঠায় না — তখন লোকালটাই থাকে
          'extra_phones': m.containsKey('extra_phones')
              ? (m['extra_phones'] ?? '')
              : (local?['extra_phones'] ?? ''),
          // পুরোনো সার্ভার এই ঘর পাঠায় না — তখন লোকালটাই থাকে
          'plan': m.containsKey('plan')
              ? (m['plan'] ?? '')
              : (local?['plan'] ?? ''),
          'address': m['address'],
          'due_date': m['due_date'],
          'reminder_at': m['reminder_at'],
          'created_at': m['created_at'],
          'updated_at': m['updated_at'],
          'deleted': m['deleted'] == true ? 1 : 0,
          'dirty': 0,
          'photo': photos[m] ?? '',
        };
        int id;
        if (local == null) {
          id = await txn.insert('customers', {...values, 'uid': m['uid']});
        } else if ((m['updated_at'] as int) >= (local['updated_at'] as int)) {
          id = local['id'] as int;
          final old = (local['photo'] as String?) ?? '';
          if (old.isNotEmpty &&
              values['photo'] == '' &&
              m['updated_at'] == local['updated_at']) {
            // পুরনো অ্যাপ ছবি ছাড়া পাঠিয়েছিল; লোকাল ছবি রেখে আবার আপলোড হবে।
            values['photo'] = old;
            values['dirty'] = 1;
          } else if (old.isNotEmpty && old != values['photo']) {
            stale.add(old);
          }
          await txn.update(
            'customers',
            values,
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          continue;
        }
        (m['deleted'] == true ? removed : changed).add(id);
      }
      for (final m in entries.cast<Map<String, dynamic>>()) {
        final customer = (await txn.query(
          'customers',
          columns: ['id'],
          where: 'uid = ?',
          whereArgs: [m['customer_uid']],
        )).firstOrNull;
        if (customer == null) continue;
        final local = (await txn.query(
          'entries',
          columns: ['id', 'updated_at'],
          where: 'uid = ?',
          whereArgs: [m['uid']],
        )).firstOrNull;
        final values = {
          'customer_id': customer['id'],
          'customer_uid': m['customer_uid'],
          'type': m['type'],
          'amount': m['amount'],
          'date': m['date'],
          'note': m['note'],
          'updated_at': m['updated_at'],
          'deleted': m['deleted'] == true ? 1 : 0,
          'dirty': 0,
        };
        if (local == null) {
          await txn.insert('entries', {...values, 'uid': m['uid']});
        } else if ((m['updated_at'] as int) >= (local['updated_at'] as int)) {
          await txn.update(
            'entries',
            values,
            where: 'id = ?',
            whereArgs: [local['id']],
          );
        } else {
          continue;
        }
        changed.add(customer['id'] as int);
      }
      for (final m in logs.cast<Map<String, dynamic>>()) {
        final customer = (await txn.query(
          'customers',
          columns: ['id'],
          where: 'uid = ?',
          whereArgs: [m['customer_uid']],
        )).firstOrNull;
        if (customer == null) continue;
        final local = (await txn.query(
          'contact_logs',
          columns: ['id', 'updated_at'],
          where: 'uid = ?',
          whereArgs: [m['uid']],
        )).firstOrNull;
        final values = {
          'customer_id': customer['id'],
          'customer_uid': m['customer_uid'],
          'kind': m['kind'],
          'note': m['note'] ?? '',
          'at': m['at'],
          'updated_at': m['updated_at'],
          'deleted': m['deleted'] == true ? 1 : 0,
          'dirty': 0,
        };
        if (local == null) {
          await txn.insert('contact_logs', {...values, 'uid': m['uid']});
        } else if ((m['updated_at'] as int) >= (local['updated_at'] as int)) {
          await txn.update(
            'contact_logs',
            values,
            where: 'id = ?',
            whereArgs: [local['id']],
          );
        }
      }
    });
    if (logs.isNotEmpty) logsChanged.value++;
    // নতুন ছবি না আসা (বাতিল রো) ফাইল রাখা হবে; শুধু বদলে যাওয়া পুরনো ফাইল মোছা।
    for (final f in stale) {
      await deletePhoto(f);
    }
    await refresh();
    for (final id in removed) {
      await Notifier.cancel(id);
    }
    for (final id in changed.difference(removed)) {
      final c = byId(id);
      if (c != null) await Notifier.schedule(c);
    }
  }
}
