import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';

/// নতুন প্রোডাক্ট বা আগেরটা এডিট — নাম, কেনা দাম, বিক্রি দাম। [initialName] দিলে
/// (শুধু নতুন তৈরির সময়) নামের ঘর আগে থেকেই ভরা থাকে — যেমন বিক্রয়ে ফ্রি-টেক্সট
/// লেখা নাম সরাসরি প্রোডাক্ট লিস্টে যুক্ত করার সময়।
/// নতুন হলে id ফেরত দেয়, বাতিল করলে null।
Future<int?> showProductForm(
  BuildContext context, {
  Product? product,
  String initialName = '',
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ProductFormSheet(product: product, initialName: initialName),
);

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.product, this.initialName = ''});
  final Product? product;
  final String initialName;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final _name = TextEditingController(
    text: widget.product?.name ?? widget.initialName,
  );
  late final _buy = TextEditingController(
    text: widget.product == null ? '' : _fmt(widget.product!.buyPrice),
  );
  late final _sell = TextEditingController(
    text: widget.product == null ? '' : _fmt(widget.product!.sellPrice),
  );
  late var _unit = widget.product?.unit ?? ProductUnit.piece;
  bool _saving = false;

  static String _fmt(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [_name, _buy, _sell]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final buy = parseAmount(_buy.text) ?? 0;
    final sell = parseAmount(_sell.text) ?? 0;
    if (name.isEmpty) return toast(context, 'প্রোডাক্টের নাম লিখুন');

    setState(() => _saving = true);
    final store = Store.instance;
    int id;
    if (widget.product == null) {
      id = await store.addProduct(
        name: name,
        buyPrice: buy,
        sellPrice: sell,
        unit: _unit,
      );
    } else {
      id = widget.product!.id;
      await store.updateProduct(
        widget.product!,
        name: name,
        buyPrice: buy,
        sellPrice: sell,
        unit: _unit,
      );
    }
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'প্রোডাক্ট এডিট' : 'নতুন প্রোডাক্ট',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'বন্ধ করুন',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'নাম (যেমন: খাতা, জিপি কার্ড, বিকাশ ক্যাশ-ইন)',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ProductUnit>(
              segments: const [
                ButtonSegment(
                  value: ProductUnit.piece,
                  label: Text('পিস (সংখ্যা ধরে)'),
                  icon: Icon(Icons.inventory_2_outlined),
                ),
                ButtonSegment(
                  value: ProductUnit.amount,
                  label: Text('টাকা (amount ধরে)'),
                  icon: Icon(Icons.currency_exchange_rounded),
                ),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'কেনা দাম',
                      prefixText: '৳ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sell,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'বিক্রি দাম',
                      prefixText: '৳ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: reportColor),
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
