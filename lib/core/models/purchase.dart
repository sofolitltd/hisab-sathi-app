import 'package:hisab_sathi/core/models/model_utils.dart';

/// প্রোডাক্ট রিস্টক/ক্রয়ের রেকর্ড — সেভের সময় প্রোডাক্টের buy_price এই
/// unitCost-এ আপডেট হয়, যাতে পরের বিক্রয়ের লাভ হিসাব সর্বশেষ কস্ট ধরে।
class Purchase {
  final int id;
  final String uid;
  final int productId;
  final String productUid;
  final double quantity;
  final double unitCost;
  final DateTime date;
  final String note;

  const Purchase({
    required this.id,
    required this.uid,
    required this.productId,
    required this.productUid,
    required this.quantity,
    required this.unitCost,
    required this.date,
    this.note = '',
  });

  double get totalCost => unitCost * quantity;

  factory Purchase.fromMap(Map<String, Object?> m) => Purchase(
    id: m['id'] as int,
    uid: m['uid'] as String,
    productId: m['product_id'] as int,
    productUid: m['product_uid'] as String,
    quantity: ((m['quantity'] as num?) ?? 0).toDouble(),
    unitCost: ((m['unit_cost'] as num?) ?? 0).toDouble(),
    date: dateFromMillis(m['date'])!,
    note: (m['note'] as String?) ?? '',
  );
}
