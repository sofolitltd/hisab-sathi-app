import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/voice/voice.dart';
import 'package:hisab_sathi/core/widgets/name_avatar.dart';
import 'package:hisab_sathi/features/customers/customer_picker.dart';

/// নতুন বাকির শিটের মতো: মাইক, তালিকা থেকে বাছাই, আর লিখতে লিখতে আগের
/// একই রকম নাম দেখায় — যাতে একই মানুষ দুবার না বানানো হয়।
class CustomerNameField extends StatelessWidget {
  const CustomerNameField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isNew,
    required this.onExisting,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isNew;

  /// আগে থেকে থাকা কাস্টমার বাছাই হলে।
  final ValueChanged<Customer> onExisting;

  @override
  Widget build(BuildContext context) => RawAutocomplete<Customer>(
    textEditingController: controller,
    focusNode: focusNode,
    displayStringForOption: (c) => c.name,
    optionsBuilder: (v) {
      final q = v.text.trim().toLowerCase();
      if (!isNew || q.isEmpty) return const Iterable<Customer>.empty();
      return Store.instance.customers
          .where(
            (c) =>
                c.name.toLowerCase().contains(q) ||
                c.phones.any((p) => p.contains(q)),
          )
          .take(5);
    },
    onSelected: onExisting,
    fieldViewBuilder: (context, field, focus, _) => TextField(
      controller: field,
      focusNode: focus,
      autofocus: isNew,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: 'নাম',
        prefixIcon: const Icon(Icons.person_outline_rounded),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder(
              valueListenable: field,
              builder: (context, v, _) => v.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'মুছুন',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: field.clear,
                    ),
            ),
            if (isNew)
              IconButton(
                tooltip: 'তালিকা থেকে বাছাই',
                icon: const Icon(Icons.people_alt_outlined),
                onPressed: () async {
                  final c = await pickCustomer(context);
                  if (c != null && context.mounted) onExisting(c);
                },
              ),
            MicButton(onFinal: (t) => field.text = t, onText: (_) {}),
          ],
        ),
      ),
    ),
    optionsViewBuilder: (context, onSelected, options) {
      final cs = Theme.of(context).colorScheme;
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300,
              maxWidth: MediaQuery.sizeOf(context).width - 40,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  child: Text(
                    'আগে থেকেই আছে — চাপলে তার খাতা খুলবে',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
                for (final c in options)
                  ListTile(
                    leading: NameAvatar(c, radius: 18),
                    title: Text(c.name),
                    subtitle: Text(
                      c.hasDue
                          ? '${LedgerText.of(c.direction).addTitle} ${taka(c.balance)}'
                          : (c.phone.isEmpty ? '—' : c.phone),
                    ),
                    onTap: () => onSelected(c),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
