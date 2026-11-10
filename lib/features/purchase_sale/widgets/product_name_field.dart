import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/product_picker.dart';

/// প্রোডাক্টের নাম লিখলে আগের প্রোডাক্টের সাজেশন; তালিকা থেকেও বাছাই করা যায়।
/// নামটা ঐচ্ছিক — লিস্টে না থাকা নতুন নাম লিখলেও সেভ করা যায়, শুধু তখন লাভ
/// হিসাব করা যায় না (buy price জানা নেই)।
class ProductNameField extends StatefulWidget {
  const ProductNameField({
    super.key,
    required this.onChanged,
    required this.onSelected,
  });

  /// লেখা বদলালেই (বাছাই না করলেও) নতুন নাম।
  final ValueChanged<String> onChanged;
  final ValueChanged<Product> onSelected;

  @override
  State<ProductNameField> createState() => _ProductNameFieldState();
}

class _ProductNameFieldState extends State<ProductNameField> {
  TextEditingController? _acController;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Product>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Product>.empty();
        return Store.instance.products
            .where((p) => p.name.toLowerCase().contains(q))
            .take(5);
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, controller, focus, onSubmit) {
        if (!identical(_acController, controller)) {
          _acController = controller;
          controller.addListener(() => widget.onChanged(controller.text));
        }
        return TextField(
          controller: controller,
          focusNode: focus,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'প্রোডাক্ট (ঐচ্ছিক) — যেমন কলম',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, v, _) => v.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'মুছুন',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: controller.clear,
                        ),
                ),
                IconButton(
                  tooltip: 'প্রোডাক্ট সার্চ',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () async {
                    final p = await pickProduct(context);
                    if (p != null) widget.onSelected(p);
                  },
                ),
              ],
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 260,
              maxWidth: MediaQuery.sizeOf(context).width - 40,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final p in options)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_rounded),
                    title: Text(p.name),
                    subtitle: Text(
                      'কেনা ${taka(p.buyPrice)} · বিক্রি ${taka(p.sellPrice)}',
                    ),
                    onTap: () => onSelected(p),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
