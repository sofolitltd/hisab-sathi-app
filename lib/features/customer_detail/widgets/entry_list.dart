import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/features/customer_detail/widgets/entry_tile.dart';

/// একজনের লেনদেনের তালিকা — লোড হচ্ছে, ফাঁকা, বা কার্ডে সাজানো এন্ট্রি।
class EntryList extends StatelessWidget {
  const EntryList({
    super.key,
    required this.entries,
    required this.text,
    required this.onTap,
  });

  /// null = এখনো লোড হচ্ছে।
  final List<Entry>? entries;
  final LedgerText text;
  final ValueChanged<Entry> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = entries;
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'এখনো কোনো লেনদেন নেই',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64),
                EntryTile(
                  entry: list[i],
                  text: text,
                  onTap: () => onTap(list[i]),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'এডিট বা মুছতে এন্ট্রিতে চাপুন',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
