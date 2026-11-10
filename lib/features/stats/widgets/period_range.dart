import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/stats/stats_period.dart';
import 'package:hisab_sathi/features/stats/widgets/range_nav.dart';

/// সময়ভিত্তিক ফিল্টারের (চিপ + ‹তারিখ›) কমন লজিক — আয়-ব্যয় ও দৈনিক
/// রিপোর্ট, সব জায়গায় একই রকম ফিল্টার (চিপে বদলালে আজ থেকে আবার শুরু,
/// তীরে আগে-পিছে, মাঝে চাপলে ক্যালেন্ডার)।
mixin PeriodRange<T extends StatefulWidget> on State<T> {
  StatsPeriod period = StatsPeriod.today;
  DateTime anchor = today();

  (DateTime, DateTime) range() {
    final a = anchor;
    return switch (period) {
      StatsPeriod.today => (a, DateTime(a.year, a.month, a.day + 1)),
      StatsPeriod.week => (
        DateTime(a.year, a.month, a.day - 6),
        DateTime(a.year, a.month, a.day + 1),
      ),
      StatsPeriod.month => (
        DateTime(a.year, a.month),
        DateTime(a.year, a.month + 1),
      ),
      StatsPeriod.year => (DateTime(a.year), DateTime(a.year + 1)),
      StatsPeriod.all => (DateTime(2000), DateTime(a.year + 1)),
    };
  }

  /// ফিল্টার বদলালে কল হয় — সাবক্লাস এখানে নতুন করে ডাটা লোড করে।
  void onLoad();

  void shift(int dir) {
    final a = anchor;
    var next = switch (period) {
      StatsPeriod.today => DateTime(a.year, a.month, a.day + dir),
      StatsPeriod.week => DateTime(a.year, a.month, a.day + 7 * dir),
      StatsPeriod.month => DateTime(a.year, a.month + dir),
      StatsPeriod.year => DateTime(a.year + dir),
      StatsPeriod.all => a,
    };
    if (next.isAfter(today())) next = today();
    setState(() => anchor = next);
    onLoad();
  }

  Future<void> pickAnchor(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: anchor,
      firstDate: DateTime(2020),
      lastDate: today(),
      helpText: switch (period) {
        StatsPeriod.week => '৭ দিনের শেষ দিন',
        StatsPeriod.month => 'যেকোনো দিন বাছাই করুন — সেই মাস দেখাবে',
        StatsPeriod.year => 'যেকোনো দিন বাছাই করুন — সেই বছর দেখাবে',
        _ => 'কোন দিন',
      },
    );
    if (d == null || !mounted) return;
    setState(() => anchor = DateTime(d.year, d.month, d.day));
    onLoad();
  }

  Widget buildFilter() {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in StatsPeriod.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(statsPeriodLabels[p]!),
                    selected: period == p,
                    onSelected: (_) {
                      setState(() {
                        period = p;
                        anchor = today();
                      });
                      onLoad();
                    },
                  ),
                ),
            ],
          ),
        ),
        if (period != StatsPeriod.all)
          Builder(
            builder: (context) => RangeNav(
              period: period,
              anchor: anchor,
              onShift: shift,
              onPick: () => pickAnchor(context),
            ),
          ),
      ],
    );
  }
}
