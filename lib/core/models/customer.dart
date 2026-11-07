import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/installment_plan.dart';
import 'package:hisab_sathi/core/models/model_utils.dart';

class Customer {
  final int id;

  /// balance শূন্য থাকলে কোন খাতায় দেখানো হবে তার ডিফল্ট (তৈরির সময়ের ট্যাব) —
  /// আসল খাতা সবসময় [direction] থেকে আসে, এই ফিল্ড সরাসরি ব্যবহার না করাই ভালো।
  final Ledger ledger;
  final String name;
  final String phone;

  /// মূল নম্বরের বাইরে আরও নম্বর (সর্বোচ্চ [maxExtraPhones]টি)।
  final List<String> extraPhones;
  final String address;

  /// কম্প্রেস করা ছবির লোকাল পাথ (ঐচ্ছিক)।
  final String photo;

  /// কবে টাকা দেবে বলেছে।
  final DateTime? dueDate;

  /// কখন রিমাইন্ডার দেখাবে।
  final DateTime? reminderAt;
  final DateTime createdAt;

  /// মোট বাকি (বাকি - জমা)। ডাটাবেস query থেকে হিসাব হয়।
  final double balance;
  final DateTime? lastEntryAt;

  final DateTime? lastGaveAt, lastGotAt;

  /// শেষ কবে এই দিকের হিসাব বেড়েছিল — পাওনায় শেষ দিলাম, দেনায় শেষ পেলাম।
  DateTime? get lastBakiAt => direction == Ledger.pabo ? lastGaveAt : lastGotAt;

  /// কিস্তিতে আদায়ের পরিকল্পনা (না থাকলে null)।
  final InstallmentPlan? plan;

  /// পরিকল্পনা শুরুর পর থেকে মোট জমা — ডাটাবেস থেকে হিসাব হয়।
  final double planPaid;

  const Customer({
    required this.id,
    this.ledger = Ledger.pabo,
    required this.name,
    this.phone = '',
    this.extraPhones = const [],
    this.address = '',
    this.photo = '',
    this.dueDate,
    this.reminderAt,
    required this.createdAt,
    this.balance = 0,
    this.lastEntryAt,
    this.lastGaveAt,
    this.lastGotAt,
    this.plan,
    this.planPaid = 0,
  });

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
    id: m['id'] as int,
    ledger: m['ledger'] == 'debo' ? Ledger.debo : Ledger.pabo,
    name: m['name'] as String,
    phone: (m['phone'] as String?) ?? '',
    extraPhones: splitPhones(m['extra_phones'] as String?),
    address: (m['address'] as String?) ?? '',
    photo: (m['photo'] as String?) ?? '',
    dueDate: dateFromMillis(m['due_date']),
    reminderAt: dateFromMillis(m['reminder_at']),
    createdAt: dateFromMillis(m['created_at'])!,
    balance: ((m['balance'] as num?) ?? 0).toDouble(),
    lastEntryAt: dateFromMillis(m['last_entry_at']),
    lastGaveAt: dateFromMillis(m['last_baki_at']),
    lastGotAt: dateFromMillis(m['last_joma_at']),
    plan: InstallmentPlan.decode(m['plan'] as String?),
    planPaid: ((m['plan_paid'] as num?) ?? 0).toDouble(),
  );

  /// পাওনা না দেনা — balance-এর sign থেকে লাইভ হিসাব, কখনো স্টোর হয় না।
  /// balance শূন্য হলে (নতুন/মিটে যাওয়া ব্যক্তি) `ledger`-এর স্টোরড ডিফল্টে পড়ে —
  /// সেটা শুধু তৈরির সময় কোন ট্যাব খোলা ছিল তার টাই-ব্রেকার, আর কিছু না।
  Ledger get direction => balance > 0.009
      ? Ledger.pabo
      : balance < -0.009
      ? Ledger.debo
      : ledger;

  bool get hasDue => balance.abs() > 0.009;

  PlanStatus? get planStatus => plan?.status(planPaid);

  /// কিস্তি চলছে (শেষ হয়নি, বাকিও আছে)।
  bool get onPlan => hasDue && planStatus != null && !planStatus!.done;

  /// সব নম্বর, মূলটা আগে।
  List<String> get phones => [if (phone.isNotEmpty) phone, ...extraPhones];
}

const maxExtraPhones = 2;

/// ডাটাবেসে বাড়তি নম্বরগুলো এক লাইনে একটা করে রাখা থাকে।
List<String> splitPhones(String? v) => (v ?? '')
    .split('\n')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

String joinPhones(Iterable<String> phones) =>
    phones.map((s) => s.trim()).where((s) => s.isNotEmpty).join('\n');
