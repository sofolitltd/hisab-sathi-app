import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/stats/stats_period.dart';

class RecoveryCard extends StatelessWidget {
  const RecoveryCard({
    super.key,
    required this.totalDue,
    required this.allTime,
    required this.text,
  });
  final double totalDue;
  final StatsTotals? allTime;
  final LedgerText text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final given = allTime?.baki ?? 0;
    final rate = given <= 0 ? 0.0 : (allTime!.joma / given).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'এখন ${text.total}',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      Text(
                        taka(totalDue),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: bakiColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      text.rate,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '${bn((rate * 100).round())}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 10,
                backgroundColor: bakiColor.withValues(alpha: .15),
                color: jomaColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'এ পর্যন্ত ${text.added} ${taka(given)}, ${text.reduced} ${taka(allTime?.joma ?? 0)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
