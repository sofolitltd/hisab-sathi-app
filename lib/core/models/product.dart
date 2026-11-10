/// প্রোডাক্টের পরিমাণ কী হিসেবে গোনা হয় — পিস (সংখ্যা) নাকি টাকা (amount-ভিত্তিক,
/// যেমন মোবাইল ব্যাংকিং ক্যাশ-ইন যেখানে "পরিমাণ" আসলে লেনদেনের টাকার অঙ্ক)।
enum ProductUnit { piece, amount }

extension ProductUnitLabel on ProductUnit {
  String get label => switch (this) {
    ProductUnit.piece => 'পিস',
    ProductUnit.amount => 'টাকা',
  };

  String get quantityHint => switch (this) {
    ProductUnit.piece => 'পরিমাণ (পিস)',
    ProductUnit.amount => 'পরিমাণ (৳)',
  };
}

/// ক্রয়-বিক্রয়ের প্রোডাক্ট — সাধারণ পণ্য (খাতা, কলম) বা ফিক্সড-দামের মোবাইল
/// ব্যাংকিং/কার্ড কমিশন আইটেম (যেমন "বিকাশ ক্যাশ-ইন (প্রতি হাজার)", "জিপি কার্ড")।
/// buy/sell price এক ইউনিটের দাম — ইউনিট কী বোঝায় তা নামেই স্পষ্ট থাকে।
class Product {
  final int id;
  final String uid;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final ProductUnit unit;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.uid,
    required this.name,
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.unit = ProductUnit.piece,
    required this.updatedAt,
  });

  double get profitPerUnit => sellPrice - buyPrice;

  factory Product.fromMap(Map<String, Object?> m) => Product(
    id: m['id'] as int,
    uid: m['uid'] as String,
    name: m['name'] as String,
    buyPrice: ((m['buy_price'] as num?) ?? 0).toDouble(),
    sellPrice: ((m['sell_price'] as num?) ?? 0).toDouble(),
    unit: ProductUnit.values.asNameMap()[m['unit']] ?? ProductUnit.piece,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
  );
}
