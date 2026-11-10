import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/expense_detail_sheet.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/total_card.dart';
import 'package:hisab_sathi/features/stats/widgets/period_range.dart';

/// ব্যয়ের পুরো লিস্ট — উপরে সময়ভিত্তিক ফিল্টার (আজ/৭ দিন/মাস/বছর/সব সময়)।
/// এডিট/মোছার জন্য যেকোনো আইটেমে ট্যাপ করা যায়।
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen>
    with PeriodRange {
  List<Expense>? _list;
  double? _total;

  @override
  void initState() {
    super.initState();
    onLoad();
  }

  @override
  void onLoad() {
    final (from, to) = range();
    () async {
      final store = Store.instance;
      final list = await store.expensesBetween(from, to);
      final total = await store.expenseTotalBetween(from, to);
      if (!mounted) return;
      setState(() {
        _list = list;
        _total = total;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final total = _total;
    return Scaffold(
      appBar: AppBar(title: const Text('ব্যয়ের বিস্তারিত')),
      body: RefreshIndicator(
        onRefresh: () async => onLoad(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            buildFilter(),
            const SizedBox(height: 12),
            if (list == null || total == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              TotalCard(
                label: 'মোট ব্যয়',
                value: taka(total),
                color: expenseColor,
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('এই সময়ে কোনো ব্যয় যুক্ত হয়নি')),
                )
              else
                for (final e in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: expenseColor.withValues(alpha: .12),
                          child: const Icon(
                            Icons.sell_outlined,
                            color: expenseColor,
                          ),
                        ),
                        title: Text(
                          e.category,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            fmtDateDMY(e.date),
                            if (e.note.isNotEmpty) e.note,
                          ].join(' • '),
                        ),
                        trailing: Text(
                          taka(e.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onTap: () async {
                          await showExpenseDetailSheet(context, e);
                          onLoad();
                        },
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
