import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/widgets/note_field.dart';
import 'package:hisab_sathi/features/purchase_sale/expense_history_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/report_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/expense_category_field.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/total_card.dart';

/// ব্যয় ট্যাব — ক্যাটেগরি-ভিত্তিক সাধারণ ব্যয় (দোকান ভাড়া, খাবার-দাবার,
/// বাজার ব্যয় ইত্যাদি) হাতে যুক্ত করা, আজ/এই মাস/সর্বমোট দেখা, বিস্তারিত
/// লিস্টে এডিট করা।
class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _expenseCategory = TextEditingController();
  final _expenseAmount = TextEditingController();
  final _expenseNote = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  bool _expenseSaving = false;
  List<String> _expenseCategories = [];
  double _expenseToday = 0;
  double _expenseThisMonth = 0;
  double _expenseAllTime = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenseSummary();
  }

  @override
  void dispose() {
    for (final c in [_expenseCategory, _expenseAmount, _expenseNote]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExpenseSummary() async {
    final store = Store.instance;
    final now = DateTime.now();
    final startOfDay = DateUtils.dateOnly(now);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final today = await store.expenseTotalBetween(startOfDay, endOfDay);
    final thisMonth = await store.expenseTotalBetween(startOfMonth, endOfDay);
    final allTime = await store.expenseTotalAll();
    final categories = await store.expenseCategories();
    if (!mounted) return;
    setState(() {
      _expenseToday = today;
      _expenseThisMonth = thisMonth;
      _expenseAllTime = allTime;
      _expenseCategories = categories;
    });
  }

  Future<void> _pickExpenseDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'ব্যয়ের তারিখ',
    );
    if (d == null) return;
    setState(
      () => _expenseDate = DateUtils.isSameDay(d, DateTime.now())
          ? DateTime.now()
          : d,
    );
  }

  Future<void> _saveExpense() async {
    final category = _expenseCategory.text.trim();
    final amount = parseAmount(_expenseAmount.text);
    if (category.isEmpty) return toast(context, 'ক্যাটেগরি লিখুন');
    if (amount == null || amount <= 0) {
      return toast(context, 'সঠিক টাকার অঙ্ক লিখুন');
    }

    setState(() => _expenseSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    await Store.instance.addExpense(
      category: category,
      amount: amount,
      date: _expenseDate,
      note: _expenseNote.text,
    );
    if (!mounted) return;
    setState(() {
      _expenseCategory.clear();
      _expenseAmount.clear();
      _expenseNote.clear();
      _expenseDate = DateTime.now();
      _expenseSaving = false;
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ব্যয় সেভ হয়েছে')));
    await _loadExpenseSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্যয়'),
        actions: [
          IconButton(
            tooltip: 'স্ট্যাটিস্টিক্স',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IncomeExpenseReportScreen(initialTab: 1),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExpenseCategoryField(
                    controller: _expenseCategory,
                    recent: _expenseCategories,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expenseAmount,
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
                  NoteField(controller: _expenseNote, hint: 'নোট (ঐচ্ছিক)'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      DateUtils.isSameDay(_expenseDate, DateTime.now())
                          ? 'আজ, ${fmtDateDMY(_expenseDate)}'
                          : fmtDateDMY(_expenseDate),
                    ),
                    trailing: const Text('বদলান'),
                    onTap: _pickExpenseDate,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: expenseColor,
                    ),
                    onPressed: _expenseSaving ? null : _saveExpense,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('ব্যয় সেভ করুন'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TotalCard(label: 'আজ', value: taka(_expenseToday)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TotalCard(
                  label: 'এই মাস',
                  value: taka(_expenseThisMonth),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TotalCard(
                  label: 'সর্বমোট',
                  value: taka(_expenseAllTime),
                  color: expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
              );
              await _loadExpenseSummary();
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('বিস্তারিত দেখুন'),
          ),
        ],
      ),
    );
  }
}
