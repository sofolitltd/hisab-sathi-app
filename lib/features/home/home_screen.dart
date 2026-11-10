import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/customers/people_list_page.dart';
import 'package:hisab_sathi/features/dashboard/widgets/recent_tile.dart';
import 'package:hisab_sathi/features/entries/entry_sheet.dart';
import 'package:hisab_sathi/features/home/widgets/home_cards.dart';
import 'package:hisab_sathi/features/home/widgets/top_bar.dart';
import 'package:hisab_sathi/features/purchase_sale/report_screen.dart';
import 'package:hisab_sathi/features/stats/daily_report_screen.dart';
import 'package:hisab_sathi/features/stats/stats_screen.dart';

/// হোম ট্যাব — এক নজরে পুরো ব্যবসা: দেনা-পাওনা, আজকের আয়-ব্যয়, আজকের
/// করণীয় আর সাম্প্রতিক লেনদেন। নিজে কোনো হিসাব বদলায় না; শুধু দেখায় আর
/// বিদ্যমান স্ক্রিনে পাঠায়, তাই ডেটা/API-তে কিছু যোগ করতে হয়নি।
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onProfileTap, required this.onTab});

  final VoidCallback onProfileTap;

  /// নিচের বারের ট্যাবে যাওয়ার জন্য (১ = দেনা পাওনা, ২ = আয়, ৩ = ব্যয়)।
  final ValueChanged<int> onTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = Store.instance;
  double _sales = 0, _profit = 0, _expense = 0, _purchase = 0;
  double _gotToday = 0, _gaveToday = 0;
  List<(Entry, String)> _recent = [];

  @override
  void initState() {
    super.initState();
    _store.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _store.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final from = today();
    final to = DateTime(from.year, from.month, from.day, 23, 59, 59, 999);
    final trade = await _store.profitBetween(from, to);
    final expense = await _store.expenseTotalBetween(from, to);
    final ledger = await _store.totalsBetween(from, null);
    final recent = await _store.recentEntries(5);
    if (!mounted) return;
    setState(() {
      _sales = trade.sales;
      _profit = trade.profit;
      _purchase = trade.purchaseCost;
      _expense = expense;
      _gotToday = ledger.joma;
      _gaveToday = ledger.baki;
      _recent = recent;
    });
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final due = _store.customers.where((c) => c.hasDue).toList();
        final overdue = due
            .where((c) => dueStatus(c.dueDate) == DueStatus.overdue)
            .toList();
        final dueToday = due
            .where((c) => dueStatus(c.dueDate) == DueStatus.today)
            .length;
        final pabo = _store.totalOf(Ledger.pabo);
        final debo = _store.totalOf(Ledger.debo);
        final (overduePabo, overdueDebo) = (
          _sum(overdue, Ledger.pabo),
          _sum(overdue, Ledger.debo),
        );

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                TopBar(onProfileTap: widget.onProfileTap),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _store.refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2, bottom: 12),
                          child: Text(
                            fmtDate(DateTime.now()),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        BalanceCard(
                          pabo: pabo,
                          debo: debo,
                          overduePabo: overduePabo,
                          overdueDebo: overdueDebo,
                          onPabo: () => openPeopleList(
                            context,
                            title: 'মোট পাওনা',
                            ledger: Ledger.pabo,
                          ),
                          onDebo: () => openPeopleList(
                            context,
                            title: 'মোট দেনা',
                            ledger: Ledger.debo,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            QuickAction(
                              icon: Icons.arrow_upward_rounded,
                              label: 'দিলাম',
                              color: bakiColor,
                              onTap: () => showEntrySheet(
                                context,
                                type: EntryType.baki,
                              ),
                            ),
                            QuickAction(
                              icon: Icons.arrow_downward_rounded,
                              label: 'পেলাম',
                              color: jomaColor,
                              onTap: () => showEntrySheet(
                                context,
                                type: EntryType.joma,
                              ),
                            ),
                            QuickAction(
                              icon: Icons.point_of_sale_rounded,
                              label: 'বিক্রয়',
                              color: saleColor,
                              onTap: () => widget.onTab(2),
                            ),
                            QuickAction(
                              icon: Icons.receipt_long_rounded,
                              label: 'ব্যয়',
                              color: expenseColor,
                              onTap: () => widget.onTab(3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        HomeSectionTitle(
                          'আজকের হিসাব',
                          action: 'রিপোর্ট',
                          onAction: () =>
                              _push(DailyReportScreen(date: today())),
                        ),
                        const SizedBox(height: 8),
                        TodayCard(
                          income: _sales,
                          expense: _purchase + _expense,
                          net: _profit - _expense,
                          got: _gotToday,
                          gave: _gaveToday,
                        ),
                        if (overdue.isNotEmpty || dueToday > 0) ...[
                          const SizedBox(height: 24),
                          const HomeSectionTitle('আজ করণীয়'),
                          const SizedBox(height: 8),
                          AttentionCard(
                            text: [
                              if (dueToday > 0) 'আজ মেয়াদ ${bn(dueToday)} জনের',
                              if (overdue.isNotEmpty)
                                'মেয়াদ পার ${bn(overdue.length)} জন',
                            ].join(' • '),
                            onTap: () => widget.onTab(1),
                          ),
                        ],
                        if (_recent.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          HomeSectionTitle(
                            'সাম্প্রতিক লেনদেন',
                            action: 'সব দেখুন',
                            onAction: () => widget.onTab(1),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (var i = 0; i < _recent.length; i++) ...[
                                  if (i > 0)
                                    Divider(
                                      height: 1,
                                      indent: 68,
                                      color: cs.outlineVariant.withValues(
                                        alpha: .5,
                                      ),
                                    ),
                                  RecentTile(
                                    entry: _recent[i].$1,
                                    name: _recent[i].$2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ShortcutTile(
                              icon: Icons.assessment_outlined,
                              label: 'আয়-ব্যয় রিপোর্ট',
                              onTap: () =>
                                  _push(const IncomeExpenseReportScreen()),
                            ),
                            const SizedBox(width: 12),
                            ShortcutTile(
                              icon: Icons.bar_chart_rounded,
                              label: 'পরিসংখ্যান',
                              onTap: () => _push(const StatsScreen()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _sum(List<Customer> list, Ledger l) => list
      .where((c) => c.direction == l)
      .fold(0.0, (s, c) => s + c.balance.abs());
}
