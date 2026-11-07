import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/l10n.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/features/home/shell.dart';
import 'package:hisab_sathi/features/sync/sync_service.dart';

/// অ্যাপের মূল উইজেট — থিম, ভাষা, আর ফিরে এলে সিঙ্ক।
class HisabSathiApp extends StatefulWidget {
  const HisabSathiApp({super.key});

  @override
  State<HisabSathiApp> createState() => _HisabSathiAppState();
}

class _HisabSathiAppState extends State<HisabSathiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// অ্যাপে ফিরে এলে সিঙ্ক।
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) SyncService.instance.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'হিসাব সাথী',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('bn'),
      supportedLocales: const [Locale('bn'), Locale('en')],
      localizationsDelegates: appLocalizationsDelegates,
      // ফোনে ২৪ ঘণ্টা চালু থাকলেও অ্যাপে সবসময় AM/PM
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
      // লগইন বাধ্যতামূলক না — সরাসরি খাতায় ঢোকা যায়, লগইন/ব্যাকআপ প্রোফাইল
      // থেকে পরে ইচ্ছামতো করা যায় (AuthService এখনো দরকার: init() লোকাল
      // PIN/প্রোফাইল পুনরুদ্ধার করে, auto-reconnect sync-এর জন্য)।
      home: const Shell(),
    );
  }
}
