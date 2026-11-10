import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/widgets/note_field.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/expense_category_field.dart';

/// আগের ব্যয়ের বিস্তারিত — ক্যাটেগরি/টাকা/নোট/তারিখ এডিট বা পুরোটা মোছা।
Future<void> showExpenseDetailSheet(BuildContext context, Expense expense) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseDetailSheet(expense: expense),
    );

class _ExpenseDetailSheet extends StatefulWidget {
  const _ExpenseDetailSheet({required this.expense});
  final Expense expense;

  @override
  State<_ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends State<_ExpenseDetailSheet> {
  late final _category = TextEditingController(text: widget.expense.category);
  late final _amount = TextEditingController(text: _fmt(widget.expense.amount));
  late final _note = TextEditingController(text: widget.expense.note);
  late var _date = widget.expense.date;
  List<String> _recent = [];
  bool _saving = false;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await Store.instance.expenseCategories();
    if (mounted) setState(() => _recent = list);
  }

  @override
  void dispose() {
    for (final c in [_category, _amount, _note]) {
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
      helpText: 'ব্যয়ের তারিখ',
    );
    if (d == null) return;
    setState(
      () => _date = DateUtils.isSameDay(d, DateTime.now()) ? DateTime.now() : d,
    );
  }

  Future<void> _save() async {
    final category = _category.text.trim();
    final amount = parseAmount(_amount.text);
    if (category.isEmpty) return toast(context, 'ক্যাটেগরি বাছুন');
    if (amount == null || amount <= 0) {
      return toast(context, 'সঠিক টাকার অঙ্ক লিখুন');
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    await Store.instance.updateExpense(
      widget.expense,
      category: category,
      amount: amount,
      date: _date,
      note: _note.text,
    );
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ব্যয় আপডেট হয়েছে')));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই ব্যয় মুছবেন?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Store.instance.deleteExpense(widget.expense);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ব্যয় এডিট',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'মুছুন',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
                IconButton(
                  tooltip: 'বন্ধ করুন',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpenseCategoryField(controller: _category, recent: _recent),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: expenseColor,
              ),
              decoration: const InputDecoration(
                hintText: 'টাকার অঙ্ক',
                prefixText: '৳ ',
              ),
            ),
            const SizedBox(height: 8),
            NoteField(controller: _note, hint: 'নোট (ঐচ্ছিক)'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                DateUtils.isSameDay(_date, DateTime.now())
                    ? 'আজ, ${fmtDateDMY(_date)}'
                    : fmtDateDMY(_date),
              ),
              trailing: const Text('বদলান'),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: expenseColor),
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
