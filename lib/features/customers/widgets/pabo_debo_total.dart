import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/utils/utils.dart';

/// পাওনা আর দেনা আলাদা রঙের ছোট বোতাম; শূন্যটা বাদ যায়। চাপলে শুধু সেই
/// দিক বাছাই হয়, আবার চাপলে সবাই। জায়গা কম হলে নিচের লাইনে নামে।
class PaboDeboTotal extends StatelessWidget {
  const PaboDeboTotal({
    super.key,
    required this.pabo,
    required this.debo,
    required this.selected,
    required this.onSelect,
  });
  final double pabo, debo;
  final Ledger? selected;
  final ValueChanged<Ledger?> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (pabo > 0) _chip(context, Ledger.pabo, pabo),
      if (debo > 0) _chip(context, Ledger.debo, debo),
      if (selected != null) _clear(context),
    ],
  );

  Widget _chip(BuildContext context, Ledger l, double amount) {
    final color = ledgerAccent(l, Theme.of(context).brightness);
    final on = selected == l;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: color.withValues(alpha: on ? .2 : .08),
        shape: StadiumBorder(
          side: BorderSide(color: on ? color : Colors.transparent),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelect(on ? null : l),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              '${LedgerText.of(l).name} ${taka(amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// বাছাই থাকলে আলাদা ✕ — চাপলে আবার সবাই।
  Widget _clear(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'বাছাই সরান, সবাই দেখুন',
      child: Material(
        color: cs.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onSelect(null),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
