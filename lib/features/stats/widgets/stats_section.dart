import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/contact_log/contact_log.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.iconColor,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Icon(icon, color: iconColor ?? cs.primary),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: subtitle == null ? null : Text(subtitle!),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class StatsCustomerRow extends StatelessWidget {
  const StatsCustomerRow({
    super.key,
    required this.customer,
    required this.onTap,
  });
  final Customer customer;
  final VoidCallback onTap;

  /// নম্বর থাকলে কল বা বিস্তারিত বাছাই, না থাকলে সরাসরি বিস্তারিত।
  Future<void> _actions(BuildContext context) async {
    final c = customer;
    if (c.phones.isEmpty) return onTap();
    final phone = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Text(
                taka(c.balance),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: bakiColor,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final p in c.phones)
              ListTile(
                leading: Icon(
                  Icons.call_rounded,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                title: const Text('কল করুন'),
                subtitle: Text(p),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('বিস্তারিত দেখুন'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
          ],
        ),
      ),
    );
    if (phone == null || !context.mounted) return;
    if (phone.isEmpty) {
      onTap();
    } else {
      await callPhone(context, phone);
      if (context.mounted) {
        await logContact(
          context,
          c,
          ContactKind.call,
          c.phones.length > 1 ? phone : '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return ListTile(
      onTap: () => _actions(context),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        c.dueDate == null
            ? 'তারিখ ঠিক হয়নি'
            : dueLabel(c.dueDate!, c.direction),
        style: TextStyle(color: dueColor(context, c.dueDate)),
      ),
      trailing: Text(
        taka(c.balance),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: ledgerAccent(c.direction, Theme.of(context).brightness),
        ),
      ),
    );
  }
}
