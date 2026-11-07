import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';

/// "প্রতি সপ্তাহে", "১৫ দিন পরপর", "প্রতি মাসে"।
String planEveryLabel(int every) => switch (every) {
  0 => 'প্রতি মাসে',
  7 => 'প্রতি সপ্তাহে',
  _ => '${bn(every)} দিন পরপর',
};

/// কার্ড, স্লিপ, মেসেজে এক লাইনে চলতি কিস্তির কথা।
String planNextLine(Customer c) {
  final s = c.planStatus!;
  return 'কিস্তি ${taka(s.nextAmount)} • ${fmtShortDate(s.nextDate)}';
}

/// আদায় (পাওনা) না পরিশোধ (দেনা)।
String planVerb(Ledger l) => l == Ledger.pabo ? 'আদায়' : 'পরিশোধ';
