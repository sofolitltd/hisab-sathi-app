import 'dart:convert';
import 'dart:math' as math;

/// কিস্তিতে আদায় — মোট কত, প্রতি কিস্তিতে কত, কত দিন পরপর।
/// আলাদা কোনো লেনদেন নেই: পরিকল্পনার দিন থেকে সাধারণ জমাগুলোই কিস্তি
/// হিসেবে গোনা হয়।
class InstallmentPlan {
  const InstallmentPlan({
    required this.total,
    required this.amount,
    required this.every,
    required this.start,
    required this.from,
  });

  final double total;
  final double amount;

  /// কত দিন পরপর; ০ = প্রতি মাসে একই তারিখে।
  final int every;

  /// প্রথম কিস্তির তারিখ।
  final DateTime start;

  /// এই দিন (ও পরের) জমাগুলো কিস্তিতে গোনা হয়।
  final DateTime from;

  int get count => (total / amount - 0.0001).ceil();

  /// k-তম কিস্তির তারিখ (০ থেকে)। মাসিক হলে মাসের দিন না থাকলে শেষ দিন।
  DateTime dateOf(int k) {
    if (every > 0) {
      return DateTime(start.year, start.month, start.day + every * k);
    }
    final month = DateTime(start.year, start.month + k);
    final days = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, math.min(start.day, days));
  }

  DateTime get end => dateOf(count - 1);

  PlanStatus status(double paid, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final p = math.min(paid, total);
    final done = p >= total - 0.009;
    // আজ পর্যন্ত যতগুলো কিস্তির তারিখ গেছে, ততটা দেওয়ার কথা
    var due = 0;
    while (due < count && !dateOf(due).isAfter(today)) {
      due++;
    }
    final expected = math.min(due * amount, total);
    final behind = math.max(0.0, expected - p);
    final current = math.min((p / amount + 0.0001).floor(), count - 1);
    return PlanStatus(
      paid: p,
      done: done,
      paidCount: math.min((p / amount + 0.0001).floor(), count),
      nextIndex: current,
      nextDate: dateOf(current),
      nextAmount: math.min((current + 1) * amount, total) - p,
      behind: behind,
      behindCount: (behind / amount - 0.0001).ceil(),
    );
  }

  String encode() => jsonEncode({
    'total': total,
    'amount': amount,
    'every': every,
    'start': start.millisecondsSinceEpoch,
    'from': from.millisecondsSinceEpoch,
  });

  static InstallmentPlan? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      final amount = (m['amount'] as num).toDouble();
      if (amount <= 0) return null;
      return InstallmentPlan(
        total: (m['total'] as num).toDouble(),
        amount: amount,
        every: m['every'] as int,
        start: DateTime.fromMillisecondsSinceEpoch(m['start'] as int),
        from: DateTime.fromMillisecondsSinceEpoch(m['from'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

class PlanStatus {
  const PlanStatus({
    required this.paid,
    required this.done,
    required this.paidCount,
    required this.nextIndex,
    required this.nextDate,
    required this.nextAmount,
    required this.behind,
    required this.behindCount,
  });

  /// পরিকল্পনায় এ পর্যন্ত দেওয়া (মোটের বেশি গোনা হয় না)।
  final double paid;
  final bool done;

  /// পুরোপুরি দেওয়া কিস্তি।
  final int paidCount;

  /// এখন যে কিস্তি চলছে (০ থেকে), তার তারিখ ও বাকি অংশ।
  final int nextIndex;
  final DateTime nextDate;
  final double nextAmount;

  /// আজ পর্যন্ত যা দেওয়ার কথা ছিল, তার চেয়ে কত কম।
  final double behind;
  final int behindCount;
}
