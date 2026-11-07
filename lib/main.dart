import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dena_pawna/app.dart';
import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/notifications/notifier.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';
import 'package:dena_pawna/features/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bn');
  await Notifier.init();
  await Store.instance.init();
  Notifier.onExactGranted = Store.instance.rescheduleAll;
  await AuthService.instance.init();
  await SyncService.instance.init();
  runApp(const BakiKhataApp());
}
