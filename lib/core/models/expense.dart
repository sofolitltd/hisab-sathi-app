import 'package:hisab_sathi/core/models/model_utils.dart';

/// ক্যাটেগরি-ভিত্তিক সাধারণ ব্যয় (দোকান ভাড়া, খাবার, বাজার ইত্যাদি) —
/// প্রোডাক্ট ক্রয়ের (restock) সাথে সম্পর্কহীন, স্বাধীন রেকর্ড।
class Expense {
  final int id;
  final String uid;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  const Expense({
    required this.id,
    required this.uid,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
    id: m['id'] as int,
    uid: m['uid'] as String,
    category: m['category'] as String,
    amount: ((m['amount'] as num?) ?? 0).toDouble(),
    date: dateFromMillis(m['date'])!,
    note: (m['note'] as String?) ?? '',
  );
}
