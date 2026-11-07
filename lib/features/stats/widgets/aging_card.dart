import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/customers/people_list_page.dart';
import 'package:hisab_sathi/features/stats/widgets/stats_section.dart';

/// পাওনা টাকা কোন অবস্থায় আছে — মেয়াদ পার, আজ, সামনে, তারিখ নেই।
class AgingCard extends StatelessWidget {
  const AgingCard({super.key, required this.due, required this.ledger});
  final List<Customer> due;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final buckets = <(String, Color, bool Function(Customer))>[
      (
        'মেয়াদ পার',
        bakiColor,
        (c) => dueStatus(c.dueDate) == DueStatus.overdue,
      ),
      (
        ledger == Ledger.pabo ? 'আজ দেবে' : 'আজ দিতে হবে',
        const Color(0xFFD97706),
        (c) => dueStatus(c.dueDate) == DueStatus.today,
      ),
      (
        '৭ দিনের মধ্যে',
        const Color(0xFF2563EB),
        (c) =>
            c.dueDate != null &&
            daysUntil(c.dueDate!) >= 1 &&
            daysUntil(c.dueDate!) <= 7,
      ),
      (
        '৭ দিনের পরে',
        jomaColor,
        (c) => c.dueDate != null && daysUntil(c.dueDate!) > 7,
      ),
      ('তারিখ ঠিক হয়নি', Colors.grey, (c) => c.dueDate == null),
    ];
    final total = due.fold<double>(0, (s, c) => s + c.balance.abs());
    final rows = [
      for (final (label, color, test) in buckets)
        (
          label,
          color,
          due.where(test).fold<double>(0, (s, c) => s + c.balance.abs()),
          due.where(test).length,
        ),
    ];

    return StatsSection(
      title: '${LedgerText.of(ledger).name}র অবস্থা',
      icon: Icons.donut_large_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: total <= 0
                  ? ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (_, color, amount, _) in rows)
                          if (amount > 0)
                            Expanded(
                              flex: math.max(
                                1,
                                (amount / total * 1000).round(),
                              ),
                              child: Container(color: color),
                            ),
                      ],
                    ),
            ),
          ),
        ),
        for (final (i, (label, color, amount, count)) in rows.indexed)
          ListTile(
            dense: true,
            onTap: count == 0
                ? null
                : () => openPeopleList(
                    context,
                    title: label,
                    ledger: ledger,
                    test: buckets[i].$3,
                  ),
            leading: CircleAvatar(radius: 6, backgroundColor: color),
            minLeadingWidth: 12,
            title: Text(label, style: const TextStyle(fontSize: 15)),
            subtitle: Text('${bn(count)} জন'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  taka(amount),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amount > 0 ? color : null,
                  ),
                ),
                if (count > 0) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
      ],
    );
  }
}
