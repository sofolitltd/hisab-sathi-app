part of 'store.dart';

/// কাস্টমার যোগ/বদল/মোছা ও তাদের লেনদেন পড়া।
extension StoreCustomers on Store {
  Future<List<Entry>> entriesOf(int customerId) async {
    final rows = await _db.query(
      'entries',
      where: 'customer_id = ? AND deleted = 0',
      whereArgs: [customerId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Entry.fromMap).toList();
  }

  Future<int> addCustomer({
    required String name,
    List<String> phones = const [],
    String address = '',
    String photo = '',
  }) async {
    final id = await _db.insert(
      'customers',
      _touch({
        'uid': Store.newUid(),
        'ledger': Ledger.pabo.name,
        'name': name.trim(),
        ..._phoneColumns(phones),
        'address': address.trim(),
        'photo': photo,
        'created_at': _now(),
      }),
    );
    onLocalChange?.call();
    return id;
  }

  Future<void> updateCustomer(
    int id, {
    required String name,
    List<String> phones = const [],
    String address = '',
    String photo = '',
  }) async {
    final old = byId(id)?.photo ?? '';
    if (old.isNotEmpty && old != photo) await deletePhoto(old);
    await _db.update(
      'customers',
      _touch({
        'name': name.trim(),
        ..._phoneColumns(phones),
        'address': address.trim(),
        'photo': photo,
      }),
      where: 'id = ?',
      whereArgs: [id],
    );
    await _afterChange(id);
  }

  /// প্রথম নম্বরটা মূল, বাকিগুলো বাড়তি; ফাঁকা ঘর বাদ।
  static Map<String, Object?> _phoneColumns(List<String> phones) {
    final list = splitPhones(joinPhones(phones));
    return {
      'phone': list.firstOrNull ?? '',
      'extra_phones': joinPhones(list.skip(1).take(maxExtraPhones)),
    };
  }

  Future<void> deleteCustomer(int id) async {
    final photo = byId(id)?.photo ?? '';
    if (photo.isNotEmpty) await deletePhoto(photo);
    await _db.transaction((txn) async {
      await txn.update(
        'customers',
        _touch({'deleted': 1, 'photo': ''}),
        where: 'id = ?',
        whereArgs: [id],
      );
      for (final t in ['entries', 'contact_logs']) {
        await txn.update(
          t,
          _touch({'deleted': 1}),
          where: 'customer_id = ? AND deleted = 0',
          whereArgs: [id],
        );
      }
    });
    await Notifier.cancel(id);
    await refresh();
    onLocalChange?.call();
  }
}
