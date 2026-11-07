import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/customers/people_list_page.dart';

/// মোট পাওনা ও দেনা — চাপলে সেই দিকের তালিকা।
class LedgerSummaryCard extends StatelessWidget {
  const LedgerSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    Widget cell(Ledger l, String label, int count) {
      final color = ledgerAccent(l, Theme.of(context).brightness);
      return Expanded(
        child: InkWell(
          onTap: () => openPeopleList(context, title: label, ledger: l),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    taka(store.totalOf(l)),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bn(count)} জন ›',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // শুধু যাদের সত্যিই হিসাব আছে — খোলা তালিকার সাথে সংখ্যা মেলে
    int count(Ledger l) =>
        store.all.where((c) => c.hasDue && c.direction == l).length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          cell(Ledger.pabo, 'মোট পাওনা', count(Ledger.pabo)),
          const SizedBox(height: 48, child: VerticalDivider(width: 1)),
          cell(Ledger.debo, 'মোট দেনা', count(Ledger.debo)),
        ],
      ),
    );
  }
}
