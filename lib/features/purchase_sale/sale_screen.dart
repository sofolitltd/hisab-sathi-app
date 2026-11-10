import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/voice/voice.dart';
import 'package:hisab_sathi/features/entries/widgets/entry_name_field.dart';
import 'package:hisab_sathi/features/entries/widgets/picked_customer_chip.dart';
import 'package:hisab_sathi/features/purchase_sale/product_form_sheet.dart';
import 'package:hisab_sathi/features/purchase_sale/report_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/sale_history_screen.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/product_name_field.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/total_card.dart';

/// বিক্রয় ট্যাব — ওপরে এন্ট্রি ফর্ম, নিচে আজকের বিক্রয়ের লিস্ট।
/// প্রোডাক্ট ও পরিমাণ ঐচ্ছিক — মূল জিনিস টাকার অঙ্ক। প্রোডাক্ট লিস্টের কোনো
/// নামের সাথে মিললে (বাছাই করে বা হুবহু টাইপ করে) buy price জানা থাকে, তখনই
/// লাভ-ক্ষতি দেখানো যায়; নইলে লাভের লাইনটা হাইড থাকে। বাকি থাকলে ও কাস্টমার
/// লিংক করা থাকলে সেই কাস্টমারের ledger-এ বাকি যুক্ত হয়।
class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _quantity = TextEditingController();
  final _received = TextEditingController();
  final _discount = TextEditingController();
  final _manualProfit = TextEditingController();

  Product? _product;
  String _typedName = '';
  Customer? _customer;
  String _typedCustomerName = '';
  DateTime _date = DateTime.now();
  bool _saving = false;
  List<Sale> _today = [];

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    for (final c in [_quantity, _received, _discount, _manualProfit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadToday() async {
    final from = DateUtils.dateOnly(DateTime.now());
    final to = DateTime(from.year, from.month, from.day, 23, 59, 59);
    final list = await Store.instance.salesBetween(from, to);
    if (mounted) setState(() => _today = list);
  }

  /// এক্সপ্লিসিট বাছাই (চিপ দেখানোর জন্য), নইলে হুবহু-মেলা নাম — দুটোই লাভ
  /// হিসাবের জন্য সমান কার্যকর।
  Product? get _matched {
    if (_product != null) return _product;
    final q = _typedName.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final p in Store.instance.products) {
      if (p.name.trim().toLowerCase() == q) return p;
    }
    return null;
  }

  double get _quantityValue {
    final q = parseAmount(_quantity.text);
    return q != null && q > 0 ? q : 1;
  }

  double get _receivedValue => parseAmount(_received.text) ?? 0;

  /// ইচ্ছাকৃত ছাড় — এটা বাকি নয়, মোট থেকে বাদ যায়, কাস্টমারের ledger-এ যোগ হয় না।
  double get _discountValue => parseAmount(_discount.text) ?? 0;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// প্রোডাক্ট বাছাই করলেই তার বিক্রয় দাম (× পরিমাণ) "কত টাকা পেলাম"-এ ভরে যায়।
  void _applyProduct(Product p) {
    _product = p;
    _typedName = p.name;
    _discount.clear();
    _received.text = _fmt(p.sellPrice * _quantityValue);
  }

  double get _total {
    final m = _matched;
    return m != null
        ? m.sellPrice * _quantityValue - _discountValue
        : _receivedValue;
  }

  double get _due => (_total - _receivedValue).clamp(0, double.infinity);

  double get _todayTotalSales =>
      _today.fold(0.0, (s, e) => s + e.totalAmount);
  double get _todayTotalProfit => _today.fold(0.0, (s, e) => s + (e.profit ?? 0));
  double get _todayTotalDue => _today.fold(0.0, (s, e) => s + e.due);

  /// প্রোডাক্ট লিস্টে যুক্ত করার পর সেল ফর্মটা পুরোপুরি খালি — নতুন করে বিক্রয় ঢোকানো শুরু হবে।
  Future<void> _addTypedToList() async {
    final id = await showProductForm(context, initialName: _typedName.trim());
    if (id == null || !mounted) return;
    setState(() {
      _product = null;
      _typedName = '';
      _quantity.clear();
      _received.clear();
      _discount.clear();
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'আয়ের তারিখ',
    );
    if (d == null) return;
    setState(
      () =>
          _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute),
    );
  }

  /// সময়ও রাখা হয় — একই দিনে কখন কোন কার্ড/প্রোডাক্ট বিক্রি হলো বোঝার জন্য।
  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'আয়ের সময়',
      // ফোনের সেটিংস ২৪-ঘণ্টা ফরম্যাটে থাকলেও এখানে AM/PM-ই দেখাবে।
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(
      () => _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        t.hour,
        t.minute,
      ),
    );
  }

  /// এক্সপ্লিসিট বাছাই, নইলে হুবহু-মেলা নাম — না থাকলে এই নামে নতুন কাস্টমার
  /// তৈরি হয় (`entry_sheet.dart`-এর প্যাটার্নে)।
  Future<int?> _resolveCustomerId() async {
    if (_customer != null) return _customer!.id;
    final typed = _typedCustomerName.trim();
    if (typed.isEmpty) return null;
    final existing = Store.instance.customers
        .where((c) => c.name.trim().toLowerCase() == typed.toLowerCase())
        .firstOrNull;
    if (existing != null) return existing.id;
    return Store.instance.addCustomer(name: typed);
  }

  Future<void> _save() async {
    final received = parseAmount(_received.text);
    if (received == null || received < 0) {
      return toast(context, 'কত টাকা পেলেন লিখুন');
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final customerId = await _resolveCustomerId();
    await Store.instance.addSale(
      product: _matched,
      productName: _typedName,
      quantity: _quantityValue,
      receivedAmount: received,
      discount: _matched == null ? 0 : _discountValue,
      manualProfit: _matched == null ? parseAmount(_manualProfit.text) : null,
      customerId: customerId,
      date: _date,
    );
    if (!mounted) return;
    setState(() {
      _product = null;
      _typedName = '';
      _customer = null;
      _typedCustomerName = '';
      _date = DateTime.now();
      _quantity.clear();
      _received.clear();
      _discount.clear();
      _manualProfit.clear();
      _saving = false;
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('আয় সেভ হয়েছে')));
    unawaited(Voice.instance.speak('${takaWords(received)} পেয়েছেন।'));
    await _loadToday();
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matched;
    final profit = matched == null
        ? null
        : _receivedValue - matched.buyPrice * _quantityValue;
    final profitPct =
        profit != null && _receivedValue > 0 ? profit / _receivedValue * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('আয়'),
        actions: [
          IconButton(
            tooltip: 'স্ট্যাটিস্টিক্স',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IncomeExpenseReportScreen(),
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
                  if (_product != null)
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_rounded),
                        title: Text(_product!.name),
                        subtitle: Text('একক দাম ${taka(_product!.sellPrice)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _product = null;
                            _typedName = '';
                            _received.clear();
                            _discount.clear();
                          }),
                        ),
                      ),
                    )
                  else
                    ProductNameField(
                      onChanged: (t) => setState(() => _typedName = t),
                      onSelected: (p) => setState(() => _applyProduct(p)),
                    ),
                  if (_product == null &&
                      _typedName.trim().isNotEmpty &&
                      matched == null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addTypedToList,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          '"${_typedName.trim()}" প্রোডাক্ট লিস্টে যুক্ত করুন',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _received,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            expands: true,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: saleColor,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'কত টাকা পেলাম',
                              prefixText: '৳ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: _quantity,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            expands: true,
                            maxLines: null,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: matched?.unit.label ?? 'পরিমাণ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matched != null) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _discount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'ছাড় (ঐচ্ছিক) — ইচ্ছাকৃত মাফ, বাকি নয়',
                        prefixIcon: Icon(Icons.sell_outlined),
                        prefixText: '৳ ',
                      ),
                    ),
                    if (_due > 0.009) ...[
                      const SizedBox(height: 6),
                      Text(
                        'মোট ${taka(_total)} — বাকি ${taka(_due)}',
                        style: const TextStyle(color: bakiColor),
                      ),
                    ] else if (_discountValue > 0.009) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ছাড়ের পর মোট ${taka(_total)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      profit != null && profit >= 0
                          ? 'লাভ ${taka(profit)} (${bn(profitPct.toStringAsFixed(0))}%)'
                          : 'ক্ষতি ${taka(profit ?? 0)} (${bn(profitPct.abs().toStringAsFixed(0))}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: (profit ?? 0) >= 0 ? jomaColor : bakiColor,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualProfit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'লাভ (ঐচ্ছিক) — প্রোডাক্ট না থাকলে হাতে লিখুন',
                        prefixIcon: Icon(Icons.trending_up_rounded),
                        prefixText: '৳ ',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (_customer != null)
                    PickedCustomerChip(
                      customer: _customer!,
                      text: LedgerText.of(Ledger.pabo),
                      onClear: () => setState(() {
                        _customer = null;
                        _typedCustomerName = '';
                      }),
                    )
                  else
                    EntryNameField(
                      hint: 'কাস্টমারের নাম (ঐচ্ছিক) — নতুন হলে এখানেই যুক্ত হবে',
                      text: LedgerText.of(Ledger.pabo),
                      autofocus: false,
                      onChanged: (t) => setState(() => _typedCustomerName = t),
                      onSelected: (c) => setState(() {
                        _customer = c;
                        _typedCustomerName = c.name;
                      }),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_outlined),
                          title: Text(
                            DateUtils.isSameDay(_date, DateTime.now())
                                ? 'আজ, ${fmtDateDMY(_date)}'
                                : fmtDateDMY(_date),
                          ),
                          onTap: _pickDate,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time_rounded),
                          title: Text(fmtTimeAmPm(_date.hour, _date.minute)),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: saleColor),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('আয় সেভ করুন'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('আজকের আয়', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TotalCard(label: 'মোট', value: taka(_todayTotalSales)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TotalCard(
                  label: 'লাভ',
                  value: taka(_todayTotalProfit),
                  color: jomaColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TotalCard(
                  label: 'বাকি',
                  value: taka(_todayTotalDue),
                  color: bakiColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaleHistoryScreen()),
              );
              await _loadToday();
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('বিস্তারিত দেখুন'),
          ),
        ],
      ),
    );
  }
}
