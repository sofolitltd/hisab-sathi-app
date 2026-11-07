import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/voice/voice.dart';
import 'package:dena_pawna/features/customers/customer_picker.dart';

/// নাম লিখলে আগের কাস্টমারের সাজেশন; তালিকা থেকে বাছাই ও মাইকে বলা যায়।
class EntryNameField extends StatefulWidget {
  const EntryNameField({
    super.key,
    required this.hint,
    required this.text,
    required this.onChanged,
    required this.onSelected,
  });
  final String hint;
  final LedgerText text;

  /// লেখা বদলালেই (বাছাই না করলেও) নতুন নাম।
  final ValueChanged<String> onChanged;
  final ValueChanged<Customer> onSelected;

  @override
  State<EntryNameField> createState() => _EntryNameFieldState();
}

class _EntryNameFieldState extends State<EntryNameField> {
  TextEditingController? _acController;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Customer>(
      displayStringForOption: (c) => c.name,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Customer>.empty();
        return Store.instance.customers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.phones.any((p) => p.contains(q)),
            )
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
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // লেখা থাকলে এক চাপে মুছে ফেলার ✕
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
                  tooltip: 'তালিকা থেকে বাছাই',
                  icon: const Icon(Icons.people_alt_outlined),
                  onPressed: () async {
                    final c = await pickCustomer(context);
                    if (c != null) widget.onSelected(c);
                  },
                ),
                MicButton(onFinal: (t) => controller.text = t, onText: (_) {}),
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
                for (final c in options)
                  ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: Text(c.name),
                    subtitle: Text(
                      c.hasDue
                          ? '${widget.text.addTitle} ${taka(c.balance)}'
                          : (c.phone.isEmpty
                                ? '${widget.text.addTitle} নেই'
                                : c.phone),
                    ),
                    onTap: () => onSelected(c),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
