import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/product_form_sheet.dart';

/// প্রোডাক্ট লিস্ট — অ্যাড/এডিট/মোছা।
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Product p) async {
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
    if (ok == true) await Store.instance.deleteProduct(p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোডাক্ট লিস্ট')),
      body: ListenableBuilder(
        listenable: Store.instance,
        builder: (context, _) {
          final products = Store.instance.products;
          if (products.isEmpty) {
            return const Center(
              child: Text('এখনো কোনো প্রোডাক্ট যোগ করা হয়নি'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: reportColor.withValues(alpha: .12),
                  child: Icon(Icons.inventory_2_outlined, color: reportColor),
                ),
                title: Text(p.name),
                subtitle: Text(
                  'কেনা ${taka(p.buyPrice)} · বিক্রি ${taka(p.sellPrice)} '
                  '· লাভ ${taka(p.profitPerUnit)}/${p.unit.label}',
                ),
                onTap: () => showProductForm(context, product: p),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(context, p),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('নতুন প্রোডাক্ট'),
      ),
    );
  }
}
