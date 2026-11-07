import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/widgets/name_avatar.dart';
import 'package:hisab_sathi/features/customer_detail/customer_navigation.dart';

class DueCustomerList extends StatelessWidget {
  const DueCustomerList({super.key, required this.customers});
  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < customers.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 68,
                color: cs.outlineVariant.withValues(alpha: .5),
              ),
            _row(context, customers[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Customer c) => ListTile(
    onTap: () => openCustomer(context, c.id),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    leading: NameAvatar(c, radius: 20),
    title: Text(
      c.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.lastBakiAt != null)
          Text(
            lastBakiLabel(c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        Text(
          dueLabel(c.dueDate!, c.direction),
          style: TextStyle(color: dueColor(context, c.dueDate), fontSize: 13),
        ),
      ],
    ),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          taka(c.balance),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: ledgerAccent(c.direction, Theme.of(context).brightness),
          ),
        ),
        Text(
          c.direction == Ledger.debo ? 'দেব' : 'পাব',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
