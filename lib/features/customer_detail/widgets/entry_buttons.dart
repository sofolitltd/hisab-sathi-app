import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/theme/theme.dart';

/// নিচের দুই বোতাম — হিসাব বাড়ানো (বাকি) ও কমানো (জমা)।
class EntryButtons extends StatelessWidget {
  const EntryButtons({super.key, required this.text, required this.onAdd});
  final LedgerText text;
  final ValueChanged<EntryType> onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: bakiColor),
                onPressed: () => onAdd(EntryType.baki),
                icon: const Icon(Icons.arrow_upward_rounded),
                label: Text(text.add),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: jomaColor),
                onPressed: () => onAdd(EntryType.joma),
                icon: const Icon(Icons.arrow_downward_rounded),
                label: Text(text.reduce),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
