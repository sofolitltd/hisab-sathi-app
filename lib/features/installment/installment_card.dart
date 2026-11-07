import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/theme/theme.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/installment/plan_labels.dart';
import 'package:dena_pawna/features/installment/plan_sheet.dart';

/// কাস্টমার পাতায় কিস্তির অবস্থা — না থাকলে শুরু করার বাটন।
class InstallmentCard extends StatelessWidget {
  const InstallmentCard({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final cs = Theme.of(context).colorScheme;
    final plan = c.plan;
    final s = c.planStatus;

    if (plan == null || s == null) {
      if (!c.hasDue) return const SizedBox.shrink();
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => showPlanSheet(context, c),
          leading: CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: .1),
            child: Icon(
              Icons.event_repeat_rounded,
              color: cs.primary,
              size: 20,
            ),
          ),
          title: Text(
            'কিস্তিতে ${planVerb(c.direction)} করুন',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('ছোট ছোট কিস্তিতে দেওয়া সহজ হয়'),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      );
    }

    final done = s.done || !c.hasDue;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPlanSheet(context, c),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.event_repeat_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'কিস্তি: ${taka(plan.amount)} ${planEveryLabel(plan.every)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LinearProgressIndicator(
                  value: (s.paid / plan.total).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: done ? jomaColor : cs.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${bn(s.paidCount)}/${bn(plan.count)} কিস্তি দেওয়া • '
                '${taka(s.paid)} / ${taka(plan.total)}',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              if (done)
                Text(
                  'সব কিস্তি দেওয়া হয়েছে ✓',
                  style: TextStyle(
                    color: jomaColor,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else ...[
                Text(
                  'পরের কিস্তি: ${taka(s.nextAmount)} • ${fmtDate(s.nextDate)}'
                  ' (${dueLabel(s.nextDate, c.direction)})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: dueColor(context, s.nextDate),
                  ),
                ),
                if (s.behindCount > 0)
                  Text(
                    '${bn(s.behindCount)} কিস্তি পিছিয়ে — ${taka(s.behind)}',
                    style: TextStyle(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
