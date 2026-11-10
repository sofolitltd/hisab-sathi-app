import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/voice/voice.dart';
import 'package:hisab_sathi/features/customer_detail/customer_navigation.dart';
import 'package:hisab_sathi/features/customers/widgets/customer_card.dart';

/// নাম বা মোবাইল লিখলে মিলে যাওয়া কাস্টমারের সাজেশন তালিকা; ট্যাপ করলে খাতা খোলে।
class CustomerSearch extends StatefulWidget {
  const CustomerSearch({super.key, required this.store});
  final Store store;

  @override
  State<CustomerSearch> createState() => _CustomerSearchState();
}

class _CustomerSearchState extends State<CustomerSearch> {
  final _controller = SearchController();

  Store get store => widget.store;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// বলা কথা খোঁজার ঘরে বসায়; বার থেকে বললে খোঁজার পাতাও খুলে দেয়।
  void _voice(String t) {
    if (t.isEmpty) return;
    if (!_controller.isOpen) _controller.openView();
    _controller.text = t;
    _controller.selection = TextSelection.collapsed(offset: t.length);
  }

  @override
  Widget build(BuildContext context) => SearchAnchor(
    searchController: _controller,
    viewHintText: 'নাম বা মোবাইল দিয়ে খুঁজুন',
    builder: (context, controller) => IconButton(
      tooltip: 'খুঁজুন',
      icon: const Icon(Icons.search_rounded),
      onPressed: () => controller.openView(),
    ),
    viewTrailing: [
      IconButton(
        tooltip: 'মুছুন',
        icon: const Icon(Icons.close_rounded),
        onPressed: _controller.clear,
      ),
      MicButton(onText: _voice),
    ],
    suggestionsBuilder: (context, controller) {
      final q = toEnDigits(controller.text.trim().toLowerCase());
      final list =
          store.customers
              .where(
                (c) =>
                    q.isEmpty ||
                    c.name.toLowerCase().contains(q) ||
                    c.phones.any((p) => p.contains(q)),
              )
              .toList()
            ..sort((a, b) {
              if (a.hasDue != b.hasDue) return a.hasDue ? -1 : 1;
              return a.name.compareTo(b.name);
            });
      return [
        const SizedBox(height: 12),
        for (final c in list)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: CustomerCard(
              customer: c,
              onTap: () {
                controller.closeView('');
                openCustomer(context, c.id);
              },
            ),
          ),
        // নিচে কিবোর্ড/নেভিগেশন বারের পেছনে যেন শেষ কার্ড না ঢাকে
        SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
      ];
    },
  );
}
