import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/widgets/entry_name_field.dart';
import 'package:hisab_sathi/features/entries/widgets/note_field.dart';
import 'package:hisab_sathi/features/entries/widgets/picked_customer_chip.dart';
import 'package:hisab_sathi/features/purchase_sale/product_form_sheet.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/product_name_field.dart';

/// আগের বিক্রয়ের বিস্তারিত — প্রোডাক্ট/কাস্টমার/নোট/সময়/পরিমাণ/টাকা এডিট বা পুরোটা মোছা।
Future<void> showSaleDetailSheet(BuildContext context, Sale sale) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SaleDetailSheet(sale: sale),
    );

class _SaleDetailSheet extends StatefulWidget {
  const _SaleDetailSheet({required this.sale});
  final Sale sale;

  @override
  State<_SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<_SaleDetailSheet> {
  late final _quantity = TextEditingController(text: _fmt(widget.sale.quantity));
  late final _received = TextEditingController(
    text: _fmt(widget.sale.receivedAmount),
  );
  late final _discount = TextEditingController(
    text: widget.sale.discount > 0 ? _fmt(widget.sale.discount) : '',
  );
  late final _note = TextEditingController(text: widget.sale.note);
  late final _manualProfit = TextEditingController(
    text: widget.sale.productId == null && widget.sale.profit != null
        ? _fmt(widget.sale.profit!)
        : '',
  );

  Product? _product;
  late var _typedName = widget.sale.productName;
  Customer? _customer;
  late var _typedCustomerName = '';
  late var _date = widget.sale.date;
  bool _saving = false;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    if (widget.sale.productId != null) {
      _product = Store.instance.productById(widget.sale.productId!);
    }
    if (widget.sale.customerId != null) {
      _customer = Store.instance.byId(widget.sale.customerId!);
      _typedCustomerName = _customer?.name ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_quantity, _received, _discount, _note, _manualProfit]) {
      c.dispose();
    }
    super.dispose();
  }

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

  double get _discountValue => parseAmount(_discount.text) ?? 0;

  double get _total {
    final m = _matched;
    return m != null
        ? m.sellPrice * _quantityValue - _discountValue
        : _receivedValue;
  }

  double get _due => (_total - _receivedValue).clamp(0, double.infinity);

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

  Future<void> _addTypedToList() async {
    final id = await showProductForm(context, initialName: _typedName.trim());
    if (id == null || !mounted) return;
    setState(() => _product = Store.instance.productById(id));
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
      () => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute),
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'আয়ের সময়',
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

  Future<void> _save() async {
    final received = parseAmount(_received.text);
    if (received == null || received < 0) {
      return toast(context, 'কত টাকা পেলেন লিখুন');
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final customerId = await _resolveCustomerId();
    await Store.instance.updateSale(
      widget.sale,
      product: _matched,
      productName: _typedName,
      quantity: _quantityValue,
      receivedAmount: received,
      discount: _matched == null ? 0 : _discountValue,
      manualProfit: _matched == null ? parseAmount(_manualProfit.text) : null,
      customerId: customerId,
      date: _date,
      note: _note.text,
    );
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('আয় আপডেট হয়েছে')));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('এই আয় মুছবেন?'),
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
    await Store.instance.deleteSale(widget.sale);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matched;
    final profit = matched == null
        ? null
        : _receivedValue - matched.buyPrice * _quantityValue;
    final profitPct =
        profit != null && _receivedValue > 0 ? profit / _receivedValue * 100 : 0;

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
                    'আয় এডিট',
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
                onSelected: (p) => setState(() {
                  _product = p;
                  _typedName = p.name;
                }),
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
                hint: 'কাস্টমারের নাম (ঐচ্ছিক)',
                text: LedgerText.of(Ledger.pabo),
                autofocus: false,
                onChanged: (t) => setState(() => _typedCustomerName = t),
                onSelected: (c) => setState(() {
                  _customer = c;
                  _typedCustomerName = c.name;
                }),
              ),
            const SizedBox(height: 8),
            NoteField(controller: _note, hint: 'নোট (ঐচ্ছিক)'),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(fmtDateDMY(_date)),
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
              label: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
