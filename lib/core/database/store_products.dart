part of 'store.dart';

/// ক্রয়-বিক্রয়ের প্রোডাক্ট লিস্ট (নাম + কেনা/বিক্রি দাম)।
extension StoreProducts on Store {
  Future<void> refreshProducts() async {
    final rows = await _db.query(
      'products',
      where: 'deleted = 0',
      orderBy: 'name COLLATE NOCASE',
    );
    products = rows.map(Product.fromMap).toList();
    _notify();
  }

  Product? productById(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<int> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    ProductUnit unit = ProductUnit.piece,
  }) async {
    final id = await _db.insert(
      'products',
      _touch({
        'uid': Store.newUid(),
        'name': name.trim(),
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'unit': unit.name,
      }),
    );
    onLocalChange?.call();
    await refreshProducts();
    return id;
  }

  Future<void> updateProduct(
    Product p, {
    required String name,
    required double buyPrice,
    required double sellPrice,
    required ProductUnit unit,
  }) async {
    await _db.update(
      'products',
      _touch({
        'name': name.trim(),
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'unit': unit.name,
      }),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    onLocalChange?.call();
    await refreshProducts();
  }

  Future<void> deleteProduct(Product p) async {
    await _db.update(
      'products',
      _touch({'deleted': 1}),
      where: 'id = ?',
      whereArgs: [p.id],
    );
    onLocalChange?.call();
    await refreshProducts();
  }

  /// ক্রয়ের সময় সর্বশেষ কস্ট ধরে buy_price আপডেট — পরের বিক্রয়ের লাভ হিসাব এটাই ধরবে।
  Future<void> _updateProductBuyPrice(int productId, double unitCost) async {
    await _db.update(
      'products',
      _touch({'buy_price': unitCost}),
      where: 'id = ?',
      whereArgs: [productId],
    );
    await refreshProducts();
  }
}
