import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/widgets/pill_tabs.dart';
import 'package:hisab_sathi/features/purchase_sale/expense_detail_sheet.dart';
import 'package:hisab_sathi/features/stats/widgets/metric_card.dart';
import 'package:hisab_sathi/features/stats/widgets/period_range.dart';
import 'package:hisab_sathi/features/stats/widgets/stats_section.dart';

/// আয়-ব্যয়ের রিপোর্ট — দুই ট্যাব: আয় (ক্রয়-বিক্রয়ের লাভ) ও ব্যয়
/// (দোকান ভাড়া, খাবার ইত্যাদি)। কাস্টমারের দেওয়া-পাওনার "রিপোর্ট" ট্যাব
/// থেকে আলাদা — এটা ব্যবসার আয়-ব্যয়ের হিসাব।
class IncomeExpenseReportScreen extends StatefulWidget {
  const IncomeExpenseReportScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<IncomeExpenseReportScreen> createState() =>
      _IncomeExpenseReportScreenState();
}

class _IncomeExpenseReportScreenState extends State<IncomeExpenseReportScreen>
    with SingleTickerProviderStateMixin {
  late final _tab = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab,
  );

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আয়-ব্যয় রিপোর্ট')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: AnimatedBuilder(
              animation: _tab.animation!,
              builder: (context, _) => PillTabs(
                labels: const ['আয়', 'ব্যয়'],
                selected: (_tab.animation!.value).round(),
                onChanged: (i) => setState(() => _tab.animateTo(i)),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_IncomeTab(), _ExpenseTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTab extends StatefulWidget {
  const _IncomeTab();

  @override
  State<_IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends State<_IncomeTab> with PeriodRange {
  final _store = Store.instance;

  ({double sales, double profit, double purchaseCost})? _totals;
  List<({String name, double sales, double profit})> _breakdown = [];

  @override
  void initState() {
    super.initState();
    onLoad();
  }

  @override
  void onLoad() {
    final (from, to) = range();
    () async {
      final totals = await _store.profitBetween(from, to);
      final breakdown = await _store.productBreakdown(from, to);
      if (!mounted) return;
      setState(() {
        _totals = totals;
        _breakdown = breakdown;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    return RefreshIndicator(
      onRefresh: () async => onLoad(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildFilter(),
          const SizedBox(height: 12),
          if (totals == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                MetricCard(
                  label: 'মোট আয়',
                  value: taka(totals.sales),
                  icon: Icons.point_of_sale_rounded,
                  color: saleColor,
                ),
                const SizedBox(width: 12),
                MetricCard(
                  label: 'মোট লাভ',
                  value: taka(totals.profit),
                  icon: Icons.trending_up_rounded,
                  color: reportColor,
                ),
                const SizedBox(width: 12),
                MetricCard(
                  label: 'মোট ক্রয়',
                  value: taka(totals.purchaseCost),
                  icon: Icons.shopping_cart_outlined,
                  color: purchaseColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_breakdown.isNotEmpty)
              StatsSection(
                title: 'প্রোডাক্ট অনুযায়ী',
                icon: Icons.inventory_2_outlined,
                iconColor: reportColor,
                children: [
                  for (final b in _breakdown)
                    ListTile(
                      title: Text(b.name),
                      subtitle: Text('আয় ${taka(b.sales)}'),
                      trailing: Text(
                        taka(b.profit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: reportColor,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseTab extends StatefulWidget {
  const _ExpenseTab();

  @override
  State<_ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<_ExpenseTab> with PeriodRange {
  final _store = Store.instance;

  double? _total;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    onLoad();
  }

  @override
  void onLoad() {
    final (from, to) = range();
    () async {
      final total = await _store.expenseTotalBetween(from, to);
      final expenses = await _store.expensesBetween(from, to);
      if (!mounted) return;
      setState(() {
        _total = total;
        _expenses = expenses;
      });
    }();
  }

  Future<void> _edit(Expense e) async {
    await showExpenseDetailSheet(context, e);
    onLoad();
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return RefreshIndicator(
      onRefresh: () async => onLoad(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildFilter(),
          const SizedBox(height: 12),
          if (total == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            MetricCard(
              label: 'মোট ব্যয়',
              value: taka(total),
              icon: Icons.sell_outlined,
              color: expenseColor,
            ),
            const SizedBox(height: 16),
            if (_expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('এই সময়ে কোনো ব্যয় লেখা হয়নি।')),
              )
            else
              for (final e in _expenses)
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
                      onTap: () => _edit(e),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
