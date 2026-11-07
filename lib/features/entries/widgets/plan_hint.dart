import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/installment/installment.dart';

/// বাকিতে: কিস্তির বাইরে থাকবে। জমায়: এক চাপে চলতি কিস্তির টাকা।
class PlanHint extends StatelessWidget {
  const PlanHint({
    super.key,
    required this.customer,
    required this.grows,
    required this.text,
    required this.onAmount,
  });
  final Customer customer;
  final bool grows;
  final LedgerText text;
  final ValueChanged<double> onAmount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = customer;
    final s = c.planStatus!;
    final ask = s.behind > 0 ? s.behind : s.nextAmount;
    if (!grows) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.event_repeat_rounded, size: 18),
          label: Text(
            s.behind > 0
                ? 'বকেয়া কিস্তি ${taka(ask)}'
                : 'এই কিস্তি ${taka(ask)}',
          ),
          onPressed: () => onAmount(ask),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'কিস্তি চলছে (${planNextLine(c)})। এই ${text.addTitle} কিস্তির '
              'বাইরে আলাদা থাকবে।',
              style: TextStyle(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}
