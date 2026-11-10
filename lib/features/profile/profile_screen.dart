import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/features/auth/auth_screen.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';
import 'package:hisab_sathi/features/profile/change_pin_sheet.dart';
import 'package:hisab_sathi/features/profile/edit_profile_sheet.dart';
import 'package:hisab_sathi/features/profile/widgets/ledger_summary_card.dart';
import 'package:hisab_sathi/features/profile/widgets/notification_settings.dart';
import 'package:hisab_sathi/features/profile/widgets/profile_header.dart';
import 'package:hisab_sathi/features/profile/widgets/settings_section.dart';
import 'package:hisab_sathi/features/purchase_sale/product_list_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/report_screen.dart';
import 'package:hisab_sathi/features/stats/daily_report_screen.dart';
import 'package:hisab_sathi/features/stats/stats_screen.dart';
import 'package:hisab_sathi/features/sync/sync_service.dart';
import 'package:hisab_sathi/features/sync/sync_sheet.dart';

/// প্রোফাইল: নিজের তথ্য, দোকানের তথ্য, খাতার সারসংক্ষেপ, সিঙ্ক, PIN বদল ও লগআউট।
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          auth,
          Store.instance,
          SyncService.instance,
        ]),
        builder: (context, _) {
          final acc = auth.account;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              ProfileHeader(account: acc),
              const SizedBox(height: 16),
              const LedgerSummaryCard(),
              const SizedBox(height: 16),
              SettingsSection(
                title: 'আয়-ব্যয়',
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('প্রোডাক্ট লিস্ট'),
                    subtitle: const Text('পণ্য ও কার্ড/ক্যাশ-ইনের দাম ঠিক করুন'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsSection(
                title: 'রিপোর্ট',
                children: [
                  ListTile(
                    leading: const Icon(Icons.today_outlined),
                    title: const Text('দৈনিক রিপোর্ট'),
                    subtitle: const Text('পাওনা-দেনা, বিক্রয়, ক্রয় ও ব্যয় — দিন ধরে'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyReportScreen(date: DateTime.now()),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('দেওয়া-পাওনার রিপোর্ট'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatsScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: const Text('আয়-ব্যয় রিপোর্ট'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IncomeExpenseReportScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (acc == null)
                SettingsSection(
                  title: 'অ্যাকাউন্ট',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.login_rounded),
                      title: const Text('লগইন / নতুন অ্যাকাউন্ট'),
                      subtitle: const Text(
                        'না করলেও অ্যাপ এমনিতে পুরোপুরি কাজ করবে — শুধু অনলাইন ব্যাকআপ/সিঙ্ক পাবেন না',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                    ),
                  ],
                )
              else ...[
                SettingsSection(
                  title: 'অ্যাকাউন্ট',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: const Text('প্রোফাইল এডিট'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _editProfile(context, acc),
                    ),
                    ListTile(
                      leading: const Icon(Icons.pin_rounded),
                      title: const Text('PIN বদলান'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _changePin(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud_sync_rounded),
                      title: const Text('অনলাইন ব্যাকআপ ও সিঙ্ক'),
                      subtitle: Text(
                        SyncService.instance.loggedIn ? 'চালু' : 'বন্ধ',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showSyncSheet(context),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const NotificationSettings(),
              if (acc != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('লগআউট'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text('এই ফোনের খাতার ডাটা মুছবে না।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AuthService.instance.logout();
  }

  void _editProfile(BuildContext context, Account acc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditProfileSheet(acc),
    );
  }

  void _changePin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ChangePinSheet(),
    );
  }
}
