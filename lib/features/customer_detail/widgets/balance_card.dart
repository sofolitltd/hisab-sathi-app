import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/widgets/name_avatar.dart';
import 'package:hisab_sathi/features/contact_log/contact_log.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.customer,
    required this.onReminder,
  });
  final Customer customer;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final cs = Theme.of(context).colorScheme;
    final reminderActive =
        c.reminderAt != null && c.reminderAt!.isAfter(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NameAvatar(c, radius: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.hasDue
                            ? LedgerText.of(c.direction).total
                            : (c.balance < 0
                                  ? LedgerText.of(c.direction).advance
                                  : '${LedgerText.of(c.direction).addTitle} নেই'),
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          taka(c.balance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: c.hasDue ? bakiColor : jomaColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (c.phone.isNotEmpty || c.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                [...c.phones, c.address].where((s) => s.isNotEmpty).join(' • '),
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
            if (c.hasDue) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 20,
                    color: dueColor(context, c.dueDate),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.dueDate == null
                          ? LedgerText.of(c.direction).whenUnset
                          : '${fmtDate(c.dueDate!)} • ${dueLabel(c.dueDate!, c.direction)}',
                      style: TextStyle(
                        color: dueColor(context, c.dueDate),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              DueChangeCount(customer: c),
              const SizedBox(height: 8),
              InkWell(
                onTap: onReminder,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Icon(
                      reminderActive
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      size: 20,
                      color: reminderActive ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reminderActive
                            ? 'রিমাইন্ডার: ${fmtDateTime(c.reminderAt!)}'
                            : 'রিমাইন্ডার সেট করা নেই',
                        style: TextStyle(
                          color: reminderActive
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      reminderActive ? 'বদলান' : 'সেট করুন',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
