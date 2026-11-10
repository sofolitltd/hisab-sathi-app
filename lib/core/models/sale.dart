import 'package:hisab_sathi/core/models/model_utils.dart';

/// এক বিক্রয়ের রেকর্ড। দাম সেভের সময়ের স্ন্যাপশট — প্রোডাক্টের দাম পরে বদলালেও
/// এই বিক্রয়ের লাভ হিসাব অপরিবর্তিত থাকে।
class Sale {
  final int id;
  final String uid;

  /// সেভড প্রোডাক্ট লিস্টের সাথে link (না থাকলে null — শুধু ফ্রি-টেক্সট নাম)।
  final int? productId;
  final String productUid;
  final String productName;
  final double unitBuyPrice;
  final double unitSellPrice;
  final double quantity;

  /// existing customer-এর সাথে link (না থাকলে null)।
  final int? customerId;

  /// কত টাকা হাতে পেলাম — মোট বিক্রয়ের চেয়ে কম হলে বাকি।
  final double receivedAmount;

  /// ইচ্ছাকৃত ছাড় — এটা বাকি নয়, কাস্টমারের ledger-এ যোগ হয় না।
  final double discount;
  final DateTime date;
  final String note;

  /// লাভ জানা থাকলেই এখানে মান থাকে — প্রোডাক্ট লিংক করা থাকলে স্বয়ংক্রিয়,
  /// নইলে ব্যবহারকারীর হাতে লেখা (ঐচ্ছিক)। না জানলে null — রিপোর্টের
  /// SUM(profit) স্বয়ংক্রিয়ভাবে এগুলো বাদ দেয়।
  final double? profit;

  const Sale({
    required this.id,
    required this.uid,
    this.productId,
    this.productUid = '',
    required this.productName,
    required this.unitBuyPrice,
    required this.unitSellPrice,
    required this.quantity,
    this.customerId,
    required this.receivedAmount,
    this.discount = 0,
    required this.date,
    this.note = '',
    this.profit,
  });

  /// সেভড প্রোডাক্টের সাথে link করা থাকলেই buy price জানা।
  bool get linkedToProduct => productId != null;

  /// ছাড় বাদ দেওয়ার পরের মোট — এটাই আসলে কাস্টমারের কাছে যা চাওয়া হয়েছিল।
  double get totalAmount => unitSellPrice * quantity - discount;
  double get due => (totalAmount - receivedAmount).clamp(0, double.infinity);

  factory Sale.fromMap(Map<String, Object?> m) => Sale(
    id: m['id'] as int,
    uid: m['uid'] as String,
    productId: m['product_id'] as int?,
    productUid: (m['product_uid'] as String?) ?? '',
    productName: m['product_name'] as String,
    unitBuyPrice: ((m['unit_buy_price'] as num?) ?? 0).toDouble(),
    unitSellPrice: ((m['unit_sell_price'] as num?) ?? 0).toDouble(),
    quantity: ((m['quantity'] as num?) ?? 0).toDouble(),
    customerId: m['customer_id'] as int?,
    receivedAmount: ((m['received_amount'] as num?) ?? 0).toDouble(),
    discount: ((m['discount'] as num?) ?? 0).toDouble(),
    date: dateFromMillis(m['date'])!,
    note: (m['note'] as String?) ?? '',
    profit: (m['profit'] as num?)?.toDouble(),
  );
}
