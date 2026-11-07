import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/voice/voice.dart';
import 'package:dena_pawna/core/widgets/confirm_dialog.dart';
import 'package:dena_pawna/features/contact_log/contact_log.dart';
import 'package:dena_pawna/features/customer_detail/customer_form.dart';
import 'package:dena_pawna/features/customer_detail/edit_entry_sheet.dart';
import 'package:dena_pawna/features/customer_detail/reminder_sheet.dart';
import 'package:dena_pawna/features/customer_detail/widgets/balance_card.dart';
import 'package:dena_pawna/features/customer_detail/widgets/entry_buttons.dart';
import 'package:dena_pawna/features/customer_detail/widgets/entry_list.dart';
import 'package:dena_pawna/features/customer_detail/widgets/quick_action.dart';
import 'package:dena_pawna/features/entries/entry_sheet.dart';
import 'package:dena_pawna/features/installment/installment.dart';
import 'package:dena_pawna/features/statement/statement_share.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key, required this.id});
  final int id;

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _store = Store.instance;
  List<Entry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await _store.entriesOf(widget.id);
    if (mounted) setState(() => _entries = e);
  }

  Future<void> _addEntry(Customer c, EntryType type) async {
    final saved = await showEntrySheet(context, customer: c, type: type);
    if (saved == true) {
      await _load();
      if (!mounted) return;
      final updated = _store.byId(c.id);
      toast(
        context,
        type == EntryType.joma && updated != null && !updated.hasDue
            ? LedgerText.of(c.direction).allSettled
            : 'সেভ হয়েছে',
      );
    }
  }

  /// এন্ট্রিতে চাপলে: এডিট বা মুছুন।
  Future<void> _entryActions(Entry e) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('এডিট করুন'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                'মুছুন',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditEntrySheet(
          entry: e,
          customer: _store.byId(e.customerId),
          title: _entryWord(e),
        ),
      );
      if (saved == true) await _load();
    } else if (action == 'delete') {
      await _deleteEntry(e);
    }
  }

  Future<void> _deleteEntry(Entry e) async {
    final ok = await _confirm(
      'এন্ট্রি মুছবেন?',
      '${_entryWord(e)} ${taka(e.amount)} '
          '(${fmtDate(e.date)}) মুছে যাবে।',
    );
    if (ok) {
      await _store.deleteEntry(e);
      await _load();
    }
  }

  Future<void> _deleteCustomer(Customer c) async {
    final ok = await _confirm(
      '${c.name}-কে মুছবেন?',
      'এই ${LedgerText.of(c.direction).party}-এর সব হিসাব স্থায়ীভাবে মুছে যাবে।',
    );
    if (ok) {
      await _store.deleteCustomer(c.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _entryWord(Entry e) => entryWord(e.type);

  Future<bool> _confirm(String title, String body) =>
      confirmDelete(context, title, body);

  void _call(Customer c) => callAndLog(context, c);

  void _sms(Customer c) => smsAndLog(context, c);

  Future<void> _reminder(Customer c) async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => ReminderSheet(customer: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final c = _store.byId(widget.id);
        if (c == null) return const Scaffold();
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${LedgerText.of(c.direction).name} খাতা • ${LedgerText.of(c.direction).party}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'হিসাবের ছবি শেয়ার',
                icon: const Icon(Icons.share_rounded),
                onPressed: () => shareStatement(context, c),
              ),
              IconButton(
                tooltip: 'শুনুন',
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => Voice.instance.say(context, customerSpeech(c)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') showCustomerForm(context, customer: c);
                  if (v == 'delete') _deleteCustomer(c);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('তথ্য এডিট'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('মুছে ফেলুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              BalanceCard(customer: c, onReminder: () => _reminder(c)),
              const SizedBox(height: 12),
              if (c.plan != null || c.hasDue) ...[
                InstallmentCard(customer: c),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  QuickAction(
                    icon: Icons.call_rounded,
                    label: 'কল',
                    onTap: c.phone.isEmpty ? null : () => _call(c),
                  ),
                  // তাগাদা SMS শুধু পাওনা খাতায় — নিজের দেনার জন্য না
                  if (c.direction == Ledger.pabo) ...[
                    const SizedBox(width: 8),
                    QuickAction(
                      icon: Icons.sms_outlined,
                      label: 'তাগাদা SMS',
                      onTap: c.phone.isEmpty || !c.hasDue
                          ? null
                          : () => _sms(c),
                    ),
                  ],
                  const SizedBox(width: 8),
                  QuickAction(
                    icon: Icons.alarm_rounded,
                    label: 'রিমাইন্ডার',
                    onTap: c.hasDue ? () => _reminder(c) : null,
                  ),
                ],
              ),
              if (c.phone.isEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => showCustomerForm(context, customer: c),
                  icon: const Icon(Icons.add_call),
                  label: const Text('মোবাইল নম্বর যোগ করুন'),
                ),
              ],
              const SizedBox(height: 12),
              ContactHistoryTile(customer: c),
              const SizedBox(height: 20),
              Text(
                'লেনদেনের হিসাব',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              EntryList(
                entries: _entries,
                text: LedgerText.of(c.direction),
                onTap: _entryActions,
              ),
            ],
          ),
          bottomNavigationBar: EntryButtons(
            text: LedgerText.of(c.direction),
            onAdd: (type) => _addEntry(c, type),
          ),
        );
      },
    );
  }
}
