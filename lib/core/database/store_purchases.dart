part of 'store.dart';

/// প্রোডাক্ট রিস্টক/ক্রয়।
extension StorePurchases on Store {
  Future<List<Purchase>> purchasesBetween(DateTime from, DateTime to) async {
    final rows = await _db.query(
      'purchases',
      where: 'deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Purchase.fromMap).toList();
  }

  /// নতুন ক্রয়; এর buy price-ই প্রোডাক্টের সর্বশেষ কস্ট হিসেবে সেভ হয়।
  Future<void> addPurchase({
    required int productId,
    required double quantity,
    required double unitCost,
    DateTime? date,
    String note = '',
  }) async {
    final productUid = (await _db.query(
      'products',
      columns: ['uid'],
      where: 'id = ?',
      whereArgs: [productId],
    )).first['uid'];
    await _db.insert(
      'purchases',
      _touch({
        'uid': Store.newUid(),
        'product_id': productId,
        'product_uid': productUid,
        'quantity': quantity,
        'unit_cost': unitCost,
        'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
        'note': note.trim(),
      }),
    );
    await _updateProductBuyPrice(productId, unitCost);
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }

  Future<void> deletePurchase(Purchase p) async {
    await _db.update(
      'purchases',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    onLocalChange?.call();
    unawaited(scheduleDaily());
  }
}
