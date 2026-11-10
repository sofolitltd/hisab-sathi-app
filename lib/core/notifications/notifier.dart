import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';

part 'daily_notifier.dart';

class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// নোটিফিকেশনে ট্যাপ করলে কোন কাস্টমার খুলবে।
  static final ValueNotifier<int?> openCustomer = ValueNotifier(null);

  /// রিক্যাপ/সারাংশ/ব্যবসার নোটিফিকেশনে ট্যাপ করলে কোন দিনের রিপোর্ট খুলবে।
  static final ValueNotifier<DateTime?> openReport = ValueNotifier(null);

  static void _handlePayload(String? payload) {
    if (payload == null) return;
    if (payload.startsWith('report:')) {
      final ms = int.tryParse(payload.substring('report:'.length));
      if (ms != null) openReport.value = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      openCustomer.value = int.tryParse(payload);
    }
  }

  static Future<void> init() async {
    if (kIsWeb) return; // ওয়েবে শিডিউলড নোটিফিকেশন নেই
    final prefs = await SharedPreferences.getInstance();
    TimeOfDay? time(String key) {
      final m = prefs.getInt(key);
      return m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60);
    }

    DailyNotifier.summaryTime.value =
        time(DailyNotifier._kSummaryTime) ?? DailyNotifier.summaryTime.value;
    DailyNotifier.recapTime.value =
        time(DailyNotifier._kRecapTime) ?? DailyNotifier.recapTime.value;
    DailyNotifier.recapOn.value =
        prefs.getBool(DailyNotifier._kRecapOn) ?? true;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _handlePayload(r.payload),
    );

    await refreshExact();
    // সেটিংস থেকে অনুমতি দিয়ে ফিরলে নতুন করে সব রিমাইন্ডার ঠিক সময়ে বসানো
    _lifecycle = AppLifecycleListener(
      onResume: () async {
        final was = exactAllowed.value;
        await refreshExact();
        if (!was && exactAllowed.value) onExactGranted?.call();
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _handlePayload(launch!.notificationResponse?.payload);
    }
  }

  // ---------- ঠিক সময়ে রিমাইন্ডার ----------

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // ignore: unused_field — শোনার জন্য ধরে রাখা
  static AppLifecycleListener? _lifecycle;

  /// ফোন রিমাইন্ডার ঠিক সময়ে দিতে দেয় কি না (Android 12+-এ আলাদা অনুমতি,
  /// "Alarms & reminders")। না দিলে ব্যাটারি বাঁচাতে কয়েক মিনিট দেরি হয়।
  static final exactAllowed = ValueNotifier(false);

  /// অনুমতি পাওয়ার পর আগের রিমাইন্ডারগুলো নতুন করে বসানোর হুক।
  static VoidCallback? onExactGranted;

  static AndroidScheduleMode get _mode => exactAllowed.value
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  static Future<void> refreshExact() async {
    if (kIsWeb || !Platform.isAndroid) return;
    exactAllowed.value =
        await _android?.canScheduleExactNotifications() ?? false;
  }

  /// সেটিংসের "Alarms & reminders" পাতা খোলে।
  static Future<void> requestExact() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _android?.requestExactAlarmsPermission();
    await refreshExact();
  }

  static const _kExactAsked = 'exact_asked';

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final ok = await _android?.requestNotificationsPermission() ?? true;
      // প্রথম রিমাইন্ডারের সময় একবারই ঠিক সময়ের অনুমতি চাওয়া
      final prefs = await SharedPreferences.getInstance();
      if (ok &&
          !exactAllowed.value &&
          !(prefs.getBool(_kExactAsked) ?? false)) {
        await prefs.setBool(_kExactAsked, true);
        await requestExact();
      }
      return ok;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }

  static Future<void> schedule(Customer c) async {
    if (kIsWeb) return;
    await cancel(c.id);
    final at = c.reminderAt;
    if (at == null || !c.hasDue || at.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: c.id,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      title: c.direction == Ledger.pabo
          ? 'পাওনা আদায়: ${c.name}'
          : 'দেনা পরিশোধ: ${c.name}',
      body:
          '${taka(c.balance)} ${c.direction == Ledger.pabo ? 'পাওনা' : 'দিতে হবে'}'
          '${c.dueDate != null ? ' • ${dueLabel(c.dueDate!, c.direction)}' : ''}',
      payload: '${c.id}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'due_reminder',
          'পাওনা-দেনার রিমাইন্ডার',
          channelDescription: 'টাকা দেওয়া-নেওয়ার তারিখে মনে করিয়ে দেয়',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: _mode,
    );
  }
}
