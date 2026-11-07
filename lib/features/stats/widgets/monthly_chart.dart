import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/theme/theme.dart';
import 'package:dena_pawna/features/stats/stats_period.dart';
import 'package:dena_pawna/features/stats/widgets/stats_section.dart';

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key, required this.months, required this.ledger});
  final List<StatsMonth> months;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxV = months.fold<double>(
      0,
      (m, e) => math.max(m, math.max(e.baki, e.joma)),
    );
    const barMax = 120.0;

    Widget bar(double v, Color color) => Container(
      width: 12,
      height: maxV <= 0 ? 2 : math.max(2, v / maxV * barMax),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );

    return StatsSection(
      title: 'গত ৬ মাস',
      icon: Icons.bar_chart_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              _legend(bakiColor, LedgerText.of(ledger).added),
              const SizedBox(width: 16),
              _legend(jomaColor, LedgerText.of(ledger).reduceTitle),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final m in months)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          bar(m.baki, bakiColor),
                          const SizedBox(width: 3),
                          bar(m.joma, jomaColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM', 'bn').format(m.month),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color c, String label) => Row(
    children: [
      CircleAvatar(radius: 5, backgroundColor: c),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13)),
    ],
  );
}
