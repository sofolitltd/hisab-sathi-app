import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/voice/voice.dart';
import 'package:dena_pawna/features/contact_log/contact_actions.dart';

/// কী বলল — এক চাপে নোটে বসানোর জন্য।
const _quickTags = [
  'ফোন ধরেনি',
  'নম্বর বন্ধ',
  'পরে দেবে বলেছে',
  'আংশিক দেবে',
  'এই সপ্তাহে দেবে',
  'মাসের শুরুতে দেবে',
  'দেখা করতে বলেছে',
];

/// নতুন রেকর্ড বা আগেরটা এডিট/মুছুন।
Future<void> showLogSheet(
  BuildContext context,
  Customer c, {
  ContactLog? log,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => LogSheet(customer: c, log: log),
);

class LogSheet extends StatefulWidget {
  const LogSheet({super.key, required this.customer, this.log});
  final Customer customer;
  final ContactLog? log;

  @override
  State<LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<LogSheet> {
  late ContactKind _kind = widget.log?.kind ?? ContactKind.visit;
  late final _note = TextEditingController(text: widget.log?.note);
  late DateTime _at = widget.log?.at ?? DateTime.now();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    final parts = _note.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    parts.contains(tag) ? parts.remove(tag) : parts.add(tag);
    setState(() => _note.text = parts.join(', '));
  }

  Future<void> _pickAt() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _at,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    setState(() {
      final time = t ?? TimeOfDay.fromDateTime(_at);
      _at = DateTime(d.year, d.month, d.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final store = Store.instance;
    final log = widget.log;
    if (log == null) {
      await store.addLog(widget.customer.id, _kind, note: _note.text, at: _at);
    } else {
      await store.updateLog(log.id, kind: _kind, note: _note.text, at: _at);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await Store.instance.deleteLog(widget.log!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = TextStyle(
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );
    final picked = _note.text.split(',').map((s) => s.trim()).toSet();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.log == null ? 'যোগাযোগ লিখুন' : 'যোগাযোগ এডিট',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.customer.name,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('কীভাবে', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in ContactKind.values)
                  if (k != ContactKind.due || _kind == k)
                    ChoiceChip(
                      avatar: Icon(contactIcon(k), size: 18),
                      label: Text(contactLabel(k)),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Text('কী বলল', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _quickTags)
                  FilterChip(
                    label: Text(tag),
                    selected: picked.contains(tag),
                    onSelected: (_) => _toggleTag(tag),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'নোট (ঐচ্ছিক)',
                prefixIcon: const Icon(Icons.notes_rounded),
                suffixIcon: MicButton(
                  onFinal: (t) => setState(
                    () => _note.text = [
                      _note.text.trim(),
                      t,
                    ].where((s) => s.isNotEmpty).join(', '),
                  ),
                  onText: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(fmtDateTime(_at)),
              trailing: const Text('বদলান'),
              onTap: _pickAt,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.log != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                      ),
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('মুছুন'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('সেভ করুন'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
