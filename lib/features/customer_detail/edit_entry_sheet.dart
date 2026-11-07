import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/due_reminder.dart';

/// আগের এন্ট্রির টাকা, তারিখ ও নোট বদলানো।
class EditEntrySheet extends StatefulWidget {
  const EditEntrySheet({
    super.key,
    required this.entry,
    required this.customer,
    required this.title,
  });
  final Entry entry;
  final Customer? customer;
  final String title;

  @override
  State<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<EditEntrySheet> {
  late final _amount = TextEditingController(
    text: widget.entry.amount == widget.entry.amount.roundToDouble()
        ? widget.entry.amount.toStringAsFixed(0)
        : widget.entry.amount.toString(),
  );
  late final _note = TextEditingController(text: widget.entry.note);
  late DateTime _date = widget.entry.date;

  /// বাকির এন্ট্রিতে কবে দেবে আর রিমাইন্ডারও বদলানো যায়।
  bool get _withDue =>
      widget.customer != null &&
      widget.entry.type == widget.customer!.direction.grows &&
      widget.customer != null &&
      !widget.customer!.onPlan;
  late DateTime? _due = _initialDue();
  // আগে তারিখ থাকলে রিমাইন্ডার যেমন ছিল তেমন; নতুন তারিখে ডিফল্ট চালু
  late bool _remind =
      _due == null ||
      (widget.customer?.reminderAt?.isAfter(DateTime.now()) ?? false);
  late TimeOfDay _remindTime = widget.customer?.reminderAt != null
      ? TimeOfDay.fromDateTime(widget.customer!.reminderAt!)
      : defaultReminderTime;

  DateTime? _initialDue() {
    final d = widget.customer?.dueDate;
    return d != null && daysUntil(d) >= 0 ? d : null;
  }

  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'লেনদেনের তারিখ',
    );
    if (d == null) return;
    // দিন বদলালেও আগের সময়টা থাকে, যাতে একই দিনের ক্রম না বদলায়
    setState(
      () => _date = DateTime(
        d.year,
        d.month,
        d.day,
        _date.hour,
        _date.minute,
        _date.second,
      ),
    );
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      return toast(context, 'সঠিক টাকার পরিমাণ লিখুন');
    }
    DateTime? remindAt;
    if (_withDue && _due != null && _remind) {
      remindAt = await confirmReminderAt(context, _due!, _remindTime);
      if (remindAt == null || !mounted) return;
      await Notifier.requestPermission();
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    if (_withDue) {
      await Store.instance.setSchedule(widget.customer!.id, _due, remindAt);
    }
    final prevDirection = widget.customer?.direction;
    await Store.instance.updateEntry(
      widget.entry,
      amount: amount,
      date: _date,
      note: _note.text,
    );
    final updated = Store.instance.byId(widget.entry.customerId);
    if (prevDirection != null &&
        updated != null &&
        updated.direction != prevDirection) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'হিসাব উল্টে যাওয়ায় ${updated.name} এখন '
              '${LedgerText.of(updated.direction).name} খাতায় সরে গেছে',
            ),
          ),
        );
    } else if (remindAt != null) {
      showReminderSet(messenger, remindAt);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.entry.type == EntryType.baki ? bakiColor : jomaColor;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.title} এডিট',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]')),
              ],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              decoration: InputDecoration(
                hintText: 'টাকার পরিমাণ',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '৳',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                hintText: 'নোট (ঐচ্ছিক)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(fmtDate(_date)),
              trailing: const Text('বদলান'),
              onTap: _pickDate,
            ),
            if (_withDue) ...[
              const SizedBox(height: 8),
              DueReminderFields(
                label: LedgerText.of(widget.customer!.direction).whenAsk,
                due: _due,
                remind: _remind,
                time: _remindTime,
                onDue: (d) => setState(() => _due = d),
                onRemind: (v) => setState(() => _remind = v),
                onTime: (t) => setState(() => _remindTime = t),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
