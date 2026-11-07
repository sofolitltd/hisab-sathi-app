import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/contact_log/log_sheet.dart';

String contactLabel(ContactKind k) => switch (k) {
  ContactKind.call => 'কল',
  ContactKind.sms => 'মেসেজ',
  ContactKind.visit => 'সরাসরি তাগাদা',
  ContactKind.note => 'নোট',
  ContactKind.due => 'তারিখ বদল',
};

IconData contactIcon(ContactKind k) => switch (k) {
  ContactKind.call => Icons.call_rounded,
  ContactKind.sms => Icons.sms_rounded,
  ContactKind.visit => Icons.storefront_rounded,
  ContactKind.note => Icons.sticky_note_2_rounded,
  ContactKind.due => Icons.event_repeat_rounded,
};

/// একাধিক নম্বর থাকলে কোনটায় — বেছে নিতে দেয়। বাতিল করলে null।
Future<String?> _pickPhone(BuildContext context, Customer c, IconData icon) {
  final phones = c.phones;
  if (phones.length <= 1) return Future.value(phones.firstOrNull);
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in phones)
            ListTile(
              leading: Icon(icon),
              title: Text(p),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ],
      ),
    ),
  );
}

/// কল করে ইতিহাসে লেখে; পরে "কী বলল" যোগ করার সুযোগ দেয়।
Future<void> callAndLog(BuildContext context, Customer c) async {
  final phone = await _pickPhone(context, c, Icons.call_rounded);
  if (phone == null || !context.mounted) return;
  await callPhone(context, phone);
  if (!context.mounted) return;
  await logContact(
    context,
    c,
    ContactKind.call,
    c.phones.length > 1 ? phone : '',
  );
}

/// পাওনা থাকলে তাগাদার লেখা, না থাকলে ফাঁকা মেসেজ।
String dueSmsBody(Customer c) {
  if (c.direction != Ledger.pabo || !c.hasDue) return '';
  if (c.onPlan) {
    // পুরো অঙ্কের চেয়ে ছোট কিস্তির কথা বললে দেওয়া সহজ মনে হয়
    final s = c.planStatus!;
    // পিছিয়ে থাকলে তার মধ্যে চলতি কিস্তিও ধরা আছে
    final amount = s.behind > 0 ? s.behind : s.nextAmount;
    return 'আসসালামু আলাইকুম ${c.name}, আপনার কিস্তি ${taka(amount)} '
        '${fmtDate(s.nextDate)} তারিখের মধ্যে দেওয়ার কথা। '
        'সব মিলিয়ে মোট ${taka(c.balance)}। ধন্যবাদ।';
  }
  final due = c.dueDate != null ? ' ${fmtDate(c.dueDate!)} তারিখের মধ্যে' : '';
  return 'আসসালামু আলাইকুম ${c.name}, আপনার কাছে আমার ${taka(c.balance)} '
      'পাওনা আছে। সুবিধামতো$due দিয়ে দিলে ভালো হয়। ধন্যবাদ।';
}

/// মেসেজ অ্যাপ খুলে ইতিহাসে লেখে।
Future<void> smsAndLog(BuildContext context, Customer c, [String? body]) async {
  final phone = await _pickPhone(context, c, Icons.sms_rounded);
  if (phone == null || !context.mounted) return;
  await sendSms(context, phone, body ?? dueSmsBody(c));
  if (!context.mounted) return;
  await logContact(
    context,
    c,
    ContactKind.sms,
    c.phones.length > 1 ? phone : '',
  );
}

/// ইতিহাসে লিখে নিচে "কী বলল লিখুন" দেখায়।
Future<void> logContact(
  BuildContext context,
  Customer c,
  ContactKind kind,
  String note,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final id = await Store.instance.addLog(c.id, kind, note: note);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        // কল থেকে ফিরে আসা পর্যন্ত যেন থাকে
        duration: const Duration(seconds: 12),
        content: Text('${contactLabel(kind)} ইতিহাসে লেখা হয়েছে'),
        action: SnackBarAction(
          label: 'কী বলল লিখুন',
          onPressed: () async {
            final logs = await Store.instance.logsOf(c.id);
            final log = logs.where((l) => l.id == id).firstOrNull;
            if (log != null && context.mounted) {
              showLogSheet(context, c, log: log);
            }
          },
        ),
      ),
    );
}
