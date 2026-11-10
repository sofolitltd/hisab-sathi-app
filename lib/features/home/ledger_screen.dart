import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/widgets/pill_tabs.dart';
import 'package:hisab_sathi/features/customers/customers_screen.dart';
import 'package:hisab_sathi/features/dashboard/dashboard_screen.dart';
import 'package:hisab_sathi/features/dashboard/widgets/customer_search.dart';

/// "দেনা পাওনা" ট্যাব — অন্য রিপোর্ট পেজগুলোর মতোই সাদা AppBar টাইটেল,
/// নিচে পিল-ট্যাব: দেনা-পাওনা (আগের হোম/ড্যাশবোর্ড) ও ব্যক্তি (ব্যক্তি
/// ম্যানেজ করা)। [pill] বাইরে থেকেও বদলানো যায় (যেমন ড্যাশবোর্ডের "আরও
/// দেখুন"-এ), Shell সেটা শুনে FAB-ও বদলে দেয়।
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key, required this.pill});
  final ValueNotifier<int> pill;

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  @override
  void initState() {
    super.initState();
    widget.pill.addListener(_onPillChanged);
  }

  @override
  void dispose() {
    widget.pill.removeListener(_onPillChanged);
    super.dispose();
  }

  void _onPillChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('দেনা-পাওনা'),
        actions: [CustomerSearch(store: Store.instance)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: PillTabs(
              labels: const ['দেনা-পাওনা', 'ব্যক্তি'],
              selected: widget.pill.value,
              onChanged: (i) => widget.pill.value = i,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: widget.pill.value,
              children: [
                DashboardScreen(onSeeAll: () => widget.pill.value = 1),
                const CustomersScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
