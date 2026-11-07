import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/widgets/phone_field.dart';
import 'package:hisab_sathi/features/entries/due_reminder.dart';
import 'package:hisab_sathi/features/entries/widgets/amount_field.dart';
import 'package:hisab_sathi/features/entries/widgets/entry_name_field.dart';
import 'package:hisab_sathi/features/entries/widgets/entry_sheet_header.dart';
import 'package:hisab_sathi/features/entries/widgets/note_field.dart';
import 'package:hisab_sathi/features/entries/widgets/picked_customer_chip.dart';
import 'package:hisab_sathi/features/entries/widgets/plan_hint.dart';

/// বাকি / জমা লেখার শিট।
/// [customer] না দিলে নতুন (বা আগের) কাস্টমারের নাম লিখে সরাসরি বাকি লেখা যায় —
/// এক স্ক্রিনেই কাজ শেষ।
Future<bool?> showEntrySheet(
  BuildContext context, {
  Customer? customer,
  EntryType type = EntryType.baki,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _EntrySheet(customer: customer, type: type),
);

class _EntrySheet extends StatefulWidget {
  const _EntrySheet({this.customer, required this.type});
  final Customer? customer;
  final EntryType type;

  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final _store = Store.instance;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  Customer? _picked; // নাম লিখতে গিয়ে আগের কাস্টমার বাছাই করলে
  DateTime _date = DateTime.now();
  DateTime? _due;
  TimeOfDay _remindTime = defaultReminderTime;
  bool _remind = true;
  bool _saving = false;

  Customer? get _customer => widget.customer ?? _picked;
  bool get _isBaki => widget.type == EntryType.baki;

  /// কিস্তি চললে তারিখ ও রিমাইন্ডার কিস্তি থেকেই আসে।
  bool get _onPlan => _customer?.onPlan ?? false;

  /// হিসাব থাকলে তার দিক; নতুন বা মিটে যাওয়া হলে এই এন্ট্রিই দিক ঠিক করবে।
  Ledger get _dir => (_customer?.hasDue ?? false)
      ? _customer!.direction
      : (_isBaki ? Ledger.pabo : Ledger.debo);

  /// এই এন্ট্রিতে হিসাব বাড়ে (নতুন বাকি / নতুন দেনা) — তখনই "কবে দেবে" লাগে।
  bool get _grows => widget.type == _dir.grows;
  LedgerText get _t => LedgerText.of(_dir);

  @override
  void initState() {
    super.initState();
    final existingDue = widget.customer?.dueDate;
    _due = existingDue != null && daysUntil(existingDue) >= 0
        ? existingDue
        : today().add(const Duration(days: 7));
    final r = widget.customer?.reminderAt;
    if (r != null) _remindTime = TimeOfDay.fromDateTime(r);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _amount, _note]) {
      c.dispose();
    }
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
    setState(
      () => _date = DateUtils.isSameDay(d, DateTime.now()) ? DateTime.now() : d,
    );
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (_customer == null && _name.text.trim().isEmpty) {
      return toast(context, 'নাম লিখুন');
    }
    if (amount == null || amount <= 0) {
      return toast(context, 'সঠিক টাকার পরিমাণ লিখুন');
    }

    // কিছু সেভ হওয়ার আগেই, যাতে বাতিল করলে অর্ধেক কাজ না থাকে
    DateTime? remindAt;
    if (_grows && !_onPlan && _due != null && _remind) {
      remindAt = await confirmReminderAt(context, _due!, _remindTime);
      if (remindAt == null || !mounted) return;
      await Notifier.requestPermission();
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    // একই নামে আগে কাস্টমার থাকলে নতুন করে না বানিয়ে সেটাই ব্যবহার
    final typed = _name.text.trim().toLowerCase();
    var id =
        _customer?.id ??
        _store.customers
            .where((c) => c.name.trim().toLowerCase() == typed)
            .firstOrNull
            ?.id;
    id ??= await _store.addCustomer(name: _name.text, phones: [_phone.text]);

    final prevDirection = _store.byId(id)?.direction;
    await _store.addEntry(
      customerId: id,
      type: widget.type,
      amount: amount,
      date: _date,
      note: _note.text,
      dueDate: _due,
      reminderAt: remindAt,
      updateSchedule: _grows && !_onPlan,
    );
    final updated = _store.byId(id);
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
    final accent = _isBaki ? bakiColor : jomaColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EntrySheetHeader(
              title: _isBaki ? _t.add : _t.reduce,
              subtitle: _customer?.name,
              accent: accent,
              isBaki: _isBaki,
            ),
            const SizedBox(height: 20),

            // নতুন বাকি: নাম লিখলে আগের কাস্টমারের সাজেশন আসবে
            if (widget.customer == null) ...[
              _picked == null
                  ? EntryNameField(
                      hint: _isBaki ? _t.partyHint : _t.reduceWho,
                      text: _t,
                      onChanged: (t) => _name.text = t,
                      onSelected: _select,
                    )
                  : PickedCustomerChip(
                      customer: _picked!,
                      text: _t,
                      onClear: () => setState(() {
                        _picked = null;
                        _name.clear();
                      }),
                    ),
              if (_picked == null) ...[
                const SizedBox(height: 12),
                PhoneField(controller: _phone, hint: 'মোবাইল নম্বর (ঐচ্ছিক)'),
              ],
              const SizedBox(height: 12),
            ],

            if (_onPlan) ...[
              PlanHint(
                customer: _customer!,
                grows: _grows,
                text: _t,
                onAmount: (ask) => setState(
                  () => _amount.text = ask == ask.roundToDouble()
                      ? ask.toStringAsFixed(0)
                      : ask.toStringAsFixed(2),
                ),
              ),
              const SizedBox(height: 12),
            ],

            AmountField(
              controller: _amount,
              accent: accent,
              autofocus: widget.customer != null,
            ),

            if (!_grows && (_customer?.hasDue ?? false)) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text('সব শোধ — ${taka(_customer!.balance)}'),
                  onPressed: () => setState(() {
                    final due = _customer!.balance.abs();
                    _amount.text = due.toStringAsFixed(due % 1 == 0 ? 0 : 2);
                  }),
                ),
              ),
            ],

            const SizedBox(height: 12),
            NoteField(
              controller: _note,
              hint: _isBaki ? _t.whatHint : 'নোট (ঐচ্ছিক)',
            ),

            if (_grows && !_onPlan) ...[
              const SizedBox(height: 18),
              DueReminderFields(
                label: _t.whenAsk,
                due: _due,
                remind: _remind,
                time: _remindTime,
                onDue: (d) => setState(() => _due = d),
                onRemind: (v) => setState(() => _remind = v),
                onTime: (t) => setState(() => _remindTime = t),
              ),
            ],

            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                DateUtils.isSameDay(_date, DateTime.now())
                    ? 'আজ, ${fmtDate(_date)}'
                    : fmtDate(_date),
              ),
              trailing: const Text('বদলান'),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isBaki ? _t.addSave : _t.reduceSave),
            ),
          ],
        ),
      ),
    );
  }

  void _select(Customer c) => setState(() {
    _picked = c;
    _name.text = c.name;
    final d = c.dueDate;
    if (d != null && daysUntil(d) >= 0) _due = d;
    final r = c.reminderAt;
    if (r != null) _remindTime = TimeOfDay.fromDateTime(r);
  });
}
