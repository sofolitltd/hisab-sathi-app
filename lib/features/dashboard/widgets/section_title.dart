import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/features/customers/customer_filters.dart';
import 'package:dena_pawna/features/customers/widgets/pabo_debo_total.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.customers = const [],
    this.side,
    this.onSide,
  });
  final String title;
  final List<Customer> customers;
  final Ledger? side;
  final ValueChanged<Ledger?>? onSide;

  @override
  Widget build(BuildContext context) {
    final (pabo, debo) = paboDebo(customers);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if (onSide != null)
          PaboDeboTotal(
            pabo: pabo,
            debo: debo,
            selected: side,
            onSelect: onSide!,
          ),
      ],
    );
  }
}
