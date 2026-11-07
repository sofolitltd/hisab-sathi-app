import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/customer_detail/customer_screen.dart';
import 'package:hisab_sathi/features/stats/stats_period.dart';
import 'package:hisab_sathi/features/stats/widgets/aging_card.dart';
import 'package:hisab_sathi/features/stats/widgets/metric_card.dart';
import 'package:hisab_sathi/features/stats/widgets/monthly_chart.dart';
import 'package:hisab_sathi/features/stats/widgets/range_nav.dart';
import 'package:hisab_sathi/features/stats/widgets/recovery_card.dart';
import 'package:hisab_sathi/features/stats/widgets/stats_section.dart';

/// আদায়ের হিসাব ও পরিসংখ্যান।
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _store = Store.instance;
  StatsPeriod _period = StatsPeriod.month;
  Ledger _ledger = Ledger.pabo;
  StatsTotals? _totals;
  StatsTotals? _allTime;
  List<StatsMonth>? _months;

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

  /// কোন দিন থেকে গোনা — দিনে সেই দিনটাই, ৭ দিনে শেষ দিনটা, মাসে সেই মাসের
  /// যেকোনো দিন। তীর বা ক্যালেন্ডারে বদলায়, সময়ের ধরন বদলালে আবার আজ।
  DateTime _anchor = today();

  (DateTime?, DateTime?) _range() {
    final a = _anchor;
    return switch (_period) {
      StatsPeriod.today => (a, DateTime(a.year, a.month, a.day + 1)),
      StatsPeriod.week => (
        DateTime(a.year, a.month, a.day - 6),
        DateTime(a.year, a.month, a.day + 1),
      ),
      StatsPeriod.month => (
        DateTime(a.year, a.month),
        DateTime(a.year, a.month + 1),
      ),
      StatsPeriod.year => (DateTime(a.year), DateTime(a.year + 1)),
      StatsPeriod.all => (null, null),
    };
  }

  void _shift(int dir) {
    final a = _anchor;
    var next = switch (_period) {
      StatsPeriod.today => DateTime(a.year, a.month, a.day + dir),
      StatsPeriod.week => DateTime(a.year, a.month, a.day + 7 * dir),
      StatsPeriod.month => DateTime(a.year, a.month + dir),
      StatsPeriod.year => DateTime(a.year + dir),
      StatsPeriod.all => a,
    };
    if (next.isAfter(today())) next = today();
    setState(() => _anchor = next);
    _load();
  }

  Future<void> _pickAnchor() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: today(),
      helpText: switch (_period) {
        StatsPeriod.week => '৭ দিনের শেষ দিন',
        StatsPeriod.month => 'যেকোনো দিন বাছাই করুন — সেই মাস দেখাবে',
        StatsPeriod.year => 'যেকোনো দিন বাছাই করুন — সেই বছর দেখাবে',
        _ => 'কোন দিন',
      },
    );
    if (d == null || !mounted) return;
    setState(() => _anchor = DateTime(d.year, d.month, d.day));
    _load();
  }

  Future<void> _load() async {
    final (from, to) = _range();
    final results = await Future.wait([
      _store.totalsBetween(from, to, _ledger),
      _store.totalsBetween(null, null, _ledger),
    ]);
    final months = await _store.monthly(6, _ledger);
    if (!mounted) return;
    setState(() {
      _totals = results[0];
      _allTime = results[1];
      _months = months;
    });
  }

  void _open(int id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CustomerScreen(id: id)),
  );

  void _setLedger(Ledger l) {
    if (l == _ledger) return;
    setState(() => _ledger = l);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = LedgerText.of(_ledger);
    final due = _store.customers
        .where((c) => c.hasDue && c.direction == _ledger)
        .toList();

    // আগে ধরতে হবে: মেয়াদ পার ও আজকের — বেশি দিন পার হওয়া আগে
    final collectNow =
        due
            .where(
              (c) =>
                  c.dueDate != null &&
                  (dueStatus(c.dueDate) == DueStatus.overdue ||
                      dueStatus(c.dueDate) == DueStatus.today),
            )
            .toList()
          ..sort((a, b) {
            final d = a.dueDate!.compareTo(b.dueDate!);
            return d != 0 ? d : b.balance.abs().compareTo(a.balance.abs());
          });
    final top = [...due]
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // কোন খাতার হিসাব দেখবে — পেজ নেভিগেশন না, শুধু এই রিপোর্টের
            // ফিল্টার, তাই গ্লোবাল মোডের মতো অন্য কোনো ট্যাবকে প্রভাবিত করে না।
            SegmentedButton<Ledger>(
              showSelectedIcon: false,
              segments: [
                for (final l in Ledger.values)
                  ButtonSegment(value: l, label: Text(LedgerText.of(l).name)),
              ],
              selected: {_ledger},
              onSelectionChanged: (v) => _setLedger(v.first),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in StatsPeriod.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(statsPeriodLabels[p]!),
                        selected: _period == p,
                        onSelected: (_) {
                          setState(() {
                            _period = p;
                            _anchor = today();
                          });
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (_period != StatsPeriod.all)
              RangeNav(
                period: _period,
                anchor: _anchor,
                onShift: _shift,
                onPick: _pickAnchor,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                MetricCard(
                  label: t.reduced,
                  value: _totals == null ? '—' : taka(_totals!.joma),
                  icon: Icons.south_west_rounded,
                  color: jomaColor,
                ),
                const SizedBox(width: 10),
                MetricCard(
                  label: t.added,
                  value: _totals == null ? '—' : taka(_totals!.baki),
                  icon: Icons.north_east_rounded,
                  color: bakiColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            RecoveryCard(
              totalDue: _store.totalOf(_ledger),
              allTime: _allTime,
              text: t,
            ),
            const SizedBox(height: 12),
            AgingCard(due: due, ledger: _ledger),
            const SizedBox(height: 12),
            if (collectNow.isNotEmpty) ...[
              StatsSection(
                title: _ledger == Ledger.pabo
                    ? 'আগে এদের কাছ থেকে আদায় করুন'
                    : 'আগে এদের পরিশোধ করুন',
                subtitle:
                    '${bn(collectNow.length)} জন • ${taka(collectNow.fold<double>(0, (s, c) => s + c.balance.abs()))}',
                icon: Icons.priority_high_rounded,
                iconColor: bakiColor,
                children: [
                  for (final c in collectNow.take(10))
                    StatsCustomerRow(customer: c, onTap: () => _open(c.id)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (_months != null)
              MonthlyChart(months: _months!, ledger: _ledger),
            const SizedBox(height: 12),
            if (top.isNotEmpty)
              StatsSection(
                title: t.biggest,
                icon: Icons.leaderboard_rounded,
                children: [
                  for (final c in top.take(5))
                    StatsCustomerRow(customer: c, onTap: () => _open(c.id)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
