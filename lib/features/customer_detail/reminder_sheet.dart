import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/due_reminder.dart';

class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key, required this.customer});
  final Customer customer;

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  late DateTime _due;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final r = c.reminderAt;
    _due = c.dueDate ?? today().add(const Duration(days: 1));
    if (daysUntil(_due) < 0) _due = today().add(const Duration(days: 1));
    _time = r != null ? TimeOfDay.fromDateTime(r) : defaultReminderTime;
  }

  Future<void> _save() async {
    final at = await confirmReminderAt(context, _due, _time);
    if (at == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await Notifier.requestPermission();
    await Store.instance.setSchedule(widget.customer.id, _due, at);
    showReminderSet(messenger, at);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    await Store.instance.setSchedule(
      widget.customer.id,
      widget.customer.dueDate,
      null,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final quick = [('আগামীকাল', 1), ('৩ দিন পর', 3), ('৭ দিন পর', 7)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'রিমাইন্ডার / টাকা দেওয়ার তারিখ',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, days) in quick)
                ChoiceChip(
                  label: Text(label),
                  selected: daysUntil(_due) == days,
                  onSelected: (_) =>
                      setState(() => _due = today().add(Duration(days: days))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(fmtDate(_due)),
            subtitle: Text(
              LedgerText.of(widget.customer.direction).whenAsk
                  .replaceAll('?', ''),
            ),
            trailing: const Text('বদলান'),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _due,
                firstDate: today(),
                lastDate: today().add(const Duration(days: 730)),
              );
              if (d != null) setState(() => _due = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: Text(fmtTime(_time.hour, _time.minute)),
            subtitle: const Text('কখন মনে করাবে'),
            trailing: const Text('বদলান'),
            onTap: () async {
              final t = await pickReminderTime(context, _time);
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('রিমাইন্ডার সেট করুন'),
          ),
          if (widget.customer.reminderAt != null)
            TextButton(
              onPressed: _remove,
              child: const Text('রিমাইন্ডার বন্ধ করুন'),
            ),
        ],
      ),
    );
  }
}
