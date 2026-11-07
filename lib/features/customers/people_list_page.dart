import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/customers/audio_list_sheet.dart';
import 'package:dena_pawna/features/customers/widgets/customer_card.dart';

/// পাওনা বা দেনার একটা অংশে কারা আছে (সবাই, মেয়াদ পার, আজ, …) — হোম,
/// রিপোর্ট আর প্রোফাইল সব জায়গা থেকে এই একই পাতা খোলে।
void openPeopleList(
  BuildContext context, {
  required String title,
  required Ledger ledger,
  bool Function(Customer)? test,
}) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        PeopleListPage(title: title, ledger: ledger, test: test ?? (_) => true),
  ),
);

/// তালিকা লাইভ থাকে, তাই এখান থেকে কারও পাতায় গিয়ে এন্ট্রি দিলে ফিরে এসে
/// বদলটা দেখা যায়।
class PeopleListPage extends StatelessWidget {
  const PeopleListPage({
    super.key,
    required this.title,
    required this.ledger,
    required this.test,
  });
  final String title;
  final Ledger ledger;
  final bool Function(Customer) test;

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list =
            store.customers
                .where((c) => c.hasDue && c.direction == ledger && test(c))
                .toList()
              ..sort((a, b) {
                final d = (a.dueDate ?? DateTime(9999)).compareTo(
                  b.dueDate ?? DateTime(9999),
                );
                return d != 0 ? d : b.balance.abs().compareTo(a.balance.abs());
              });
        final total = list.fold<double>(0, (s, c) => s + c.balance.abs());
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  '${LedgerText.of(ledger).name} • ${bn(list.length)} জন • '
                  '${taka(total)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ledgerAccent(ledger, Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'তালিকা শুনুন',
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: list.isEmpty
                    ? null
                    : () => showAudioListSheet(context, list),
              ),
            ],
          ),
          body: list.isEmpty
              ? Center(
                  child: Text(
                    'এখানে এখন কেউ নেই',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => CustomerCard(customer: list[i]),
                ),
        );
      },
    );
  }
}
