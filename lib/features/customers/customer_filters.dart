import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';

enum CustomerFilter {
  due,
  overdue,
  today,
  upcoming,
  plan,
  planBehind,
  paid,
  all,
}

/// তালিকার ক্রম — সাম্প্রতিক লেনদেন, না টাকার অঙ্ক।
enum CustomerSort { recent, high, low }

String filterLabel(CustomerFilter f) {
  return switch (f) {
    CustomerFilter.due => 'পাওনা/দেনা আছে',
    CustomerFilter.overdue => 'মেয়াদ পার',
    CustomerFilter.today => 'আজকের তারিখ',
    CustomerFilter.upcoming => 'সামনে',
    CustomerFilter.plan => 'কিস্তি চলছে',
    CustomerFilter.planBehind => 'কিস্তি পিছিয়ে',
    CustomerFilter.paid => 'পরিশোধিত',
    CustomerFilter.all => 'সবাই',
  };
}

(double, double) paboDebo(Iterable<Customer> list) {
  double pabo = 0, debo = 0;
  for (final c in list) {
    if (c.direction == Ledger.pabo) pabo += c.balance.abs();
    if (c.direction == Ledger.debo) debo += c.balance.abs();
  }
  return (pabo, debo);
}

/// কোন দিকের ব্যক্তি দেখাবে — null = সবাই।
bool matchesSide(Customer c, Ledger? side) =>
    side == null || (c.hasDue && c.direction == side);
