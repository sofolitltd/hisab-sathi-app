import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/features/customer_detail/customer_form.dart';
import 'package:hisab_sathi/features/customer_detail/customer_navigation.dart';
import 'package:hisab_sathi/features/customers/customers_screen.dart';
import 'package:hisab_sathi/features/dashboard/dashboard_screen.dart';
import 'package:hisab_sathi/features/entries/entry_sheet.dart';
import 'package:hisab_sathi/features/home/widgets/top_bar.dart';
import 'package:hisab_sathi/features/profile/profile_screen.dart';
import 'package:hisab_sathi/features/stats/stats_screen.dart';

/// উপরে খাতা-সুইচ, নিচে নেভিগেশন বার, আর সব ট্যাবে নতুন এন্ট্রির বাটন।
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    Notifier.openCustomer.addListener(_openFromNotification);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openFromNotification(),
    );
  }

  @override
  void dispose() {
    Notifier.openCustomer.removeListener(_openFromNotification);
    super.dispose();
  }

  void _openFromNotification() {
    final id = Notifier.openCustomer.value;
    if (id == null || !mounted) return;
    Notifier.openCustomer.value = null;
    if (Store.instance.byId(id) != null) openCustomer(context, id);
  }

  Future<void> _addFromFab() async {
    final type = await showModalBottomSheet<EntryType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: bakiColor.withValues(alpha: .12),
                child: const Icon(Icons.arrow_upward_rounded, color: bakiColor),
              ),
              title: const Text('দিলাম'),
              subtitle: const Text('কাউকে টাকা বা জিনিস দিলাম'),
              onTap: () => Navigator.pop(ctx, EntryType.baki),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: jomaColor.withValues(alpha: .12),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: jomaColor,
                ),
              ),
              title: const Text('পেলাম'),
              subtitle: const Text('কারও কাছ থেকে টাকা পেলাম'),
              onTap: () => Navigator.pop(ctx, EntryType.joma),
            ),
          ],
        ),
      ),
    );
    if (type != null && mounted) showEntrySheet(context, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        body: Column(
          children: [
            // টপ বার শুধু হোমে; বাকি ট্যাবে নিজেদের AppBar আছে
            if (_tab == 0)
              SafeArea(
                bottom: false,
                child: TopBar(onProfileTap: () => setState(() => _tab = 3)),
              ),
            Expanded(
              // হোমে উপরের প্যাডিং টপ বার নিয়ে নেয়। বাইরের Scaffold কিবোর্ডের
              // জায়গাও আগেই ছেড়ে দেয়; ভেতরের ট্যাবের Scaffold আবার ছাড়লে
              // নিচের অংশ ফাঁকা হয়ে যায়।
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .removePadding(removeTop: _tab == 0)
                    .removeViewInsets(removeBottom: true),
                child: IndexedStack(
                  index: _tab,
                  children: [
                    DashboardScreen(onSeeAll: () => setState(() => _tab = 1)),
                    const CustomersScreen(),
                    const StatsScreen(),
                    const ProfileScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _tab == 2 || _tab == 3
            ? null
            : FloatingActionButton.extended(
                onPressed: () async {
                  if (_tab == 1) {
                    final id = await showCustomerForm(context);
                    if (id != null && context.mounted) {
                      openCustomer(context, id);
                    }
                  } else {
                    await _addFromFab();
                  }
                },
                icon: Icon(
                  _tab == 1
                      ? Icons.person_add_alt_1_rounded
                      : Icons.add_rounded,
                ),
                label: Text(_tab == 1 ? 'নতুন ব্যক্তি' : 'নতুন এন্ট্রি'),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'হোম',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'ব্যক্তি',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'রিপোর্ট',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'প্রোফাইল',
            ),
          ],
        ),
      ),
    );
  }
}
