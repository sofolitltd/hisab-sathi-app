import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';

class CustomersEmptyState extends StatelessWidget {
  const CustomersEmptyState({
    super.key,
    required this.isSearch,
    required this.noCustomers,
  });
  final bool isSearch, noCustomers;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, title, sub) = isSearch
        ? (
            Icons.search_off_rounded,
            'কাউকে পাওয়া যায়নি',
            'অন্য নাম দিয়ে খুঁজুন',
          )
        : noCustomers
        ? (Icons.menu_book_rounded, 'খাতা এখনো খালি', LedgerText.pabo.emptyHint)
        : (
            Icons.check_circle_outline_rounded,
            'এখানে কেউ নেই',
            'এই তালিকায় কেউ নেই',
          );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: cs.primary.withValues(alpha: .5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
