import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/customers/customer_filters.dart';
import 'package:hisab_sathi/features/dashboard/widgets/customer_list.dart';
import 'package:hisab_sathi/features/dashboard/widgets/customer_search.dart';
import 'package:hisab_sathi/features/dashboard/widgets/hero_card.dart';
import 'package:hisab_sathi/features/dashboard/widgets/info_card.dart';
import 'package:hisab_sathi/features/dashboard/widgets/recent_tile.dart';
import 'package:hisab_sathi/features/dashboard/widgets/section_title.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _store = Store.instance;
  double _gotToday = 0, _gaveToday = 0;
  Ledger? _todaySide, _soonSide;
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
    final t = await _store.totalsBetween(today(), null);
    final recent = await _store.recentEntries(8);
    if (!mounted) return;
    setState(() {
      _gotToday = t.joma;
      _gaveToday = t.baki;
      _recent = recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final due = _store.customers.where((c) => c.hasDue).toList();
        final collectNow =
            due
                .where(
                  (c) =>
                      dueStatus(c.dueDate) == DueStatus.overdue ||
                      dueStatus(c.dueDate) == DueStatus.today,
                )
                .toList()
              ..sort((a, b) {
                final d = a.dueDate!.compareTo(b.dueDate!);
                return d != 0 ? d : b.balance.abs().compareTo(a.balance.abs());
              });
        final upcoming =
            due.where((c) => dueStatus(c.dueDate) == DueStatus.soon).toList()
              ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        final todayShown = [
          for (final c in collectNow)
            if (matchesSide(c, _todaySide)) c,
        ];
        final soonShown = [
          for (final c in upcoming)
            if (matchesSide(c, _soonSide)) c,
        ];

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _store.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  CustomerSearch(store: _store),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final (overduePabo, overdueDebo) = paboDebo(
                        due.where(
                          (c) => dueStatus(c.dueDate) == DueStatus.overdue,
                        ),
                      );
                      return HeroCard(
                        pabo: _store.totalOf(Ledger.pabo),
                        debo: _store.totalOf(Ledger.debo),
                        overduePabo: overduePabo,
                        overdueDebo: overdueDebo,
                        gotToday: _gotToday,
                        gaveToday: _gaveToday,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'আজ এগুলো দেখুন',
                    customers: collectNow,
                    side: _todaySide,
                    onSide: (s) => setState(() => _todaySide = s),
                  ),
                  const SizedBox(height: 8),
                  if (todayShown.isEmpty)
                    InfoCard(
                      icon: Icons.task_alt_rounded,
                      text: _store.customers.isEmpty
                          ? LedgerText.pabo.emptyHint
                          : 'আজ কোনো তারিখ নেই',
                    )
                  else
                    DueCustomerList(customers: todayShown.take(6).toList()),
                  if (todayShown.length > 6)
                    TextButton(
                      onPressed: widget.onSeeAll,
                      child: Text('আরও ${bn(todayShown.length - 6)} জন দেখুন'),
                    ),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionTitle(
                      title: 'সামনের ৩ দিনে',
                      customers: upcoming,
                      side: _soonSide,
                      onSide: (s) => setState(() => _soonSide = s),
                    ),
                    const SizedBox(height: 8),
                    if (soonShown.isNotEmpty)
                      DueCustomerList(customers: soonShown.take(5).toList()),
                  ],
                  if (_recent.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionTitle(title: 'সাম্প্রতিক লেনদেন'),
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
                                color: cs.outlineVariant.withValues(alpha: .5),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
