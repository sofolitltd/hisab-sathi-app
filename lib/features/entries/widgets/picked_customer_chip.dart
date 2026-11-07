import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';

/// বাছাই করা আগের কাস্টমার — ✕ চাপলে আবার নাম লেখা যায়।
class PickedCustomerChip extends StatelessWidget {
  const PickedCustomerChip({
    super.key,
    required this.customer,
    required this.text,
    required this.onClear,
  });
  final Customer customer;
  final LedgerText text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_rounded),
        title: Text(customer.name),
        subtitle: Text(
          customer.hasDue
              ? 'আগের ${text.addTitle} ${taka(customer.balance)}'
              : 'আগের ${text.addTitle} নেই',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClear,
        ),
      ),
    );
  }
}
