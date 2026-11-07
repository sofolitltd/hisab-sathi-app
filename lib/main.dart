import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:hisab_sathi/app.dart';
import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';
import 'package:hisab_sathi/features/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bn');
  await Notifier.init();
  await Store.instance.init();
  Notifier.onExactGranted = Store.instance.rescheduleAll;
  await AuthService.instance.init();
  await SyncService.instance.init();
  runApp(const HisabSathiApp());
}
