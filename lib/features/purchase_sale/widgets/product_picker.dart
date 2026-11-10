import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/product_form_sheet.dart';

/// প্রোডাক্ট লিস্ট থেকে বাছাই — না থাকলে এখান থেকেই নতুন বানানো যায়।
Future<Product?> pickProduct(BuildContext context) => showModalBottomSheet<Product>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => const _ProductPicker(),
);

class _ProductPicker extends StatefulWidget {
  const _ProductPicker();

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  final _store = Store.instance;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _visible() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _store.products;
    return _store.products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _addNew() async {
    final id = await showProductForm(context);
    if (id != null && mounted) {
      Navigator.pop(context, _store.productById(id));
    }
  }

  Future<void> _edit(Product p) async {
    await showProductForm(context, product: p);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${p.name}" মুছবেন?'),
        content: const Text('এই প্রোডাক্টের পুরনো আয়/ব্যয়ের ইতিহাস থেকে যাবে।'),
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
    if (ok == true) {
      await _store.deleteProduct(p);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible();
    return DraggableScrollableSheet(
      initialChildSize: .7,
      minChildSize: .4,
      maxChildSize: .9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'প্রোডাক্ট বাছুন',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNew,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('নতুন'),
                ),
              ],
            ),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'প্রোডাক্ট খুঁজুন',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('কোনো প্রোডাক্ট নেই'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(p.name),
                          subtitle: Text(
                            'কেনা ${taka(p.buyPrice)} · বিক্রি ${taka(p.sellPrice)}',
                          ),
                          onTap: () => Navigator.pop(context, p),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'এডিট',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(p),
                              ),
                              IconButton(
                                tooltip: 'মুছুন',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _confirmDelete(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
