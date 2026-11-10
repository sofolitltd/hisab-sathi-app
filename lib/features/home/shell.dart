import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/features/customer_detail/customer_form.dart';
import 'package:hisab_sathi/features/customer_detail/customer_navigation.dart';
import 'package:hisab_sathi/features/entries/entry_sheet.dart';
import 'package:hisab_sathi/features/home/ledger_screen.dart';
import 'package:hisab_sathi/features/home/home_screen.dart';
import 'package:hisab_sathi/features/profile/profile_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/purchase_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/sale_screen.dart';
import 'package:hisab_sathi/features/stats/daily_report_screen.dart';

/// নিচে নেভিগেশন বার — মাঝে বিক্রয়ের গোল বাটন ভেসে থাকে, পাশে হোম/দেনা
/// পাওনা/ক্রয়/প্রোফাইল। হোম ট্যাব এক নজরের সারাংশ (HomeScreen); ড্যাশবোর্ড
/// আর ব্যক্তি তালিকা "দেনা পাওনা" ট্যাবে একসাথে,
/// সাধারণ টাইটেলসহ (অন্য রিপোর্ট পেজের মতোই), উপরে পিল-ট্যাব দিয়ে সুইচ করা
/// যায়। সেই ট্যাবে আগের মতোই নতুন এন্ট্রি/ব্যক্তির FAB থাকে, কোন পিল বাছা
/// তার ওপর ভিত্তি করে।
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _ledgerPill = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    Notifier.openCustomer.addListener(_openFromNotification);
    Notifier.openReport.addListener(_openReportFromNotification);
    _ledgerPill.addListener(_onLedgerPillChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openFromNotification(),
    );
  }

  @override
  void dispose() {
    Notifier.openCustomer.removeListener(_openFromNotification);
    Notifier.openReport.removeListener(_openReportFromNotification);
    _ledgerPill.removeListener(_onLedgerPillChanged);
    _ledgerPill.dispose();
    super.dispose();
  }

  void _onLedgerPillChanged() => setState(() {});

  void _openFromNotification() {
    final id = Notifier.openCustomer.value;
    if (id == null || !mounted) return;
    Notifier.openCustomer.value = null;
    if (Store.instance.byId(id) != null) openCustomer(context, id);
  }

  void _openReportFromNotification() {
    final date = Notifier.openReport.value;
    if (date == null || !mounted) return;
    Notifier.openReport.value = null;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => DailyReportScreen(date: date)));
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
        // বাইরের Scaffold কিবোর্ডের জায়গা আগেই ছেড়ে দেয়; ভেতরের ট্যাবের
        // Scaffold আবার ছাড়লে নিচের অংশ ফাঁকা হয়ে যায়।
        body: MediaQuery(
          data: MediaQuery.of(context).removeViewInsets(removeBottom: true),
          child: IndexedStack(
            index: _tab,
            children: [
              HomeScreen(
                onProfileTap: () => setState(() => _tab = 4),
                onTab: (i) => setState(() => _tab = i),
              ),
              LedgerScreen(pill: _ledgerPill),
              const SaleScreen(),
              const PurchaseScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
        floatingActionButton: _tab == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  if (_ledgerPill.value == 1) {
                    final id = await showCustomerForm(context);
                    if (id != null && context.mounted) {
                      openCustomer(context, id);
                    }
                  } else {
                    await _addFromFab();
                  }
                },
                icon: Icon(
                  _ledgerPill.value == 1
                      ? Icons.person_add_alt_1_rounded
                      : Icons.add_rounded,
                ),
                label: Text(
                  _ledgerPill.value == 1 ? 'নতুন ব্যক্তি' : 'নতুন এন্ট্রি',
                ),
              )
            : null,
        bottomNavigationBar: _BottomBar(
          tab: _tab,
          onTab: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

/// নিচের বার — হোম, দেনা পাওনা, [মাঝে ভাসমান গোল বিক্রয় বাটন], ক্রয়, প্রোফাইল।
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.tab, required this.onTab});
  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    // Stack ফিক্সড উচ্চতা নেয় না — Material/SafeArea-এর স্বাভাবিক উচ্চতা অনুযায়ী
    // মাপ ঠিক হয়, তাই gesture-nav ইনসেটে _NavButton-এর Column overflow করে না।
    // মাঝের ভাসমান বাটন Padding(top: _fabOverlap)-এর ফাঁকা জায়গায় বসে, ওপরে উঠে থাকে।
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Material(
          elevation: 8,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: _fabOverlap),
              child: Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      icon: Icons.space_dashboard_outlined,
                      selectedIcon: Icons.space_dashboard_rounded,
                      label: 'হোম',
                      selected: tab == 0,
                      onTap: () => onTab(0),
                    ),
                  ),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.account_balance_wallet_outlined,
                      selectedIcon: Icons.account_balance_wallet_rounded,
                      label: 'দেনা পাওনা',
                      selected: tab == 1,
                      onTap: () => onTab(1),
                    ),
                  ),
                  const SizedBox(width: 74), // মাঝের ভাসমান বাটনের জায়গা
                  Expanded(
                    child: _NavButton(
                      icon: Icons.shopping_cart_outlined,
                      selectedIcon: Icons.shopping_cart_rounded,
                      label: 'ব্যয়',
                      selected: tab == 3,
                      onTap: () => onTab(3),
                    ),
                  ),
                  Expanded(
                    child: _NavButton(
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      label: 'প্রোফাইল',
                      selected: tab == 4,
                      onTap: () => onTab(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -24,
          child: _SaleFab(selected: tab == 2, onTap: () => onTab(2)),
        ),
      ],
    );
  }
}

const _fabOverlap = 12.0;

class _SaleFab extends StatelessWidget {
  const _SaleFab({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return Tooltip(
      message: 'আয়',
      child: Material(
        shape: shape,
        color: selected ? saleColor : Theme.of(context).colorScheme.primary,
        elevation: 6,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon, selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
