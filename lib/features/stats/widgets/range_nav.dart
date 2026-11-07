import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/stats/stats_period.dart';

/// ‹ তারিখ › — তীরে আগে-পিছে, মাঝে চাপলে ক্যালেন্ডার।
class RangeNav extends StatelessWidget {
  const RangeNav({
    super.key,
    required this.period,
    required this.anchor,
    required this.onShift,
    required this.onPick,
  });
  final StatsPeriod period;

  /// কোন দিন থেকে গোনা — দিনে সেই দিনটাই, ৭ দিনে শেষ দিনটা, মাসে সেই মাসের যেকোনো দিন।
  final DateTime anchor;

  /// -১ = আগের, ১ = পরের।
  final ValueChanged<int> onShift;
  final VoidCallback onPick;

  /// এখনকার সময়ের চেয়ে সামনে যাওয়া যায় না।
  bool get _atLatest {
    final t = today();
    return switch (period) {
      StatsPeriod.month => anchor.year == t.year && anchor.month == t.month,
      StatsPeriod.year => anchor.year == t.year,
      _ => !anchor.isBefore(t),
    };
  }

  String _rangeLabel() {
    final a = anchor;
    final t = today();
    switch (period) {
      case StatsPeriod.today:
        if (a == t) return 'আজ, ${fmtShortDate(a)}';
        if (a == DateTime(t.year, t.month, t.day - 1)) {
          return 'গতকাল, ${fmtShortDate(a)}';
        }
        return fmtDate(a);
      case StatsPeriod.week:
        final from = DateTime(a.year, a.month, a.day - 6);
        return '${fmtShortDate(from)} – ${fmtShortDate(a)}'
            '${a.year != t.year ? ' ${bn(a.year)}' : ''}';
      case StatsPeriod.month:
        return bn(DateFormat('MMMM yyyy', 'bn').format(a));
      case StatsPeriod.year:
        return '${bn(a.year)} সাল';
      case StatsPeriod.all:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'আগের',
            visualDensity: VisualDensity.compact,
            onPressed: () => onShift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _rangeLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'পরের',
            visualDensity: VisualDensity.compact,
            onPressed: _atLatest ? null : () => onShift(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
