import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/total_card.dart';
import 'package:hisab_sathi/features/stats/widgets/period_range.dart';

/// রাতের রিক্যাপ/সারাংশ নোটিফিকেশনে ট্যাপ করলে খোলে — পাওনা-দেনা আর
/// বিক্রয়-ক্রয়-ব্যয়ের হিসাব একসাথে। বাকি সব রিপোর্ট পেজের মতোই উপরে
/// সময়ভিত্তিক ফিল্টার (আজ/৭ দিন/মাস/বছর/সব সময়, তীরে আগে-পিছে)।
class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key, required this.date});
  final DateTime date;

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen>
    with PeriodRange {
  final _store = Store.instance;
  Map<Ledger, ({double baki, double joma, int count})>? _ledgerTotals;
  ({double sales, double profit, double purchaseCost})? _trade;
  double? _expense;

  @override
  void initState() {
    super.initState();
    anchor = DateUtils.dateOnly(widget.date);
    onLoad();
  }

  @override
  void onLoad() {
    final (from, to) = range();
    () async {
      final ledgerTotals = {
        for (final l in Ledger.values) l: await _store.totalsBetween(from, to, l),
      };
      final trade = await _store.profitBetween(from, to);
      final expense = await _store.expenseTotalBetween(from, to);
      if (!mounted) return;
      setState(() {
        _ledgerTotals = ledgerTotals;
        _trade = trade;
        _expense = expense;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    final ledgerTotals = _ledgerTotals;
    final trade = _trade;
    final expense = _expense;
    return Scaffold(
      appBar: AppBar(title: const Text('দৈনিক রিপোর্ট')),
      body: RefreshIndicator(
        onRefresh: () async => onLoad(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildFilter(),
            const SizedBox(height: 12),
            if (ledgerTotals == null || trade == null || expense == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const Text(
                'পাওনা-দেনার হিসাব',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (context) {
                      final lines = <String>[
                        for (final l in Ledger.values)
                          if (ledgerTotals[l]!.count > 0)
                            '${LedgerText.of(l).name}: ${LedgerText.of(l).added} '
                                '${taka(ledgerTotals[l]!.baki)}, ${LedgerText.of(l).reduced} '
                                '${taka(ledgerTotals[l]!.joma)} (${bn(ledgerTotals[l]!.count)}টি)',
                      ];
                      return lines.isEmpty
                          ? const Text('এই সময়ে কোনো হিসাব লেখা হয়নি।')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final l in lines)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(l),
                                  ),
                              ],
                            );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ব্যবসার সারাংশ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TotalCard(label: 'বিক্রয়', value: taka(trade.sales)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TotalCard(
                      label: 'ক্রয়',
                      value: taka(trade.purchaseCost),
                      color: expenseColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TotalCard(
                      label: 'ব্যয়',
                      value: taka(expense),
                      color: expenseColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TotalCard(
                      label: 'লাভ',
                      value: taka(trade.profit - expense),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
