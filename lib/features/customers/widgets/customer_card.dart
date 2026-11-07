import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/widgets/name_avatar.dart';
import 'package:dena_pawna/features/customer_detail/customer_navigation.dart';
import 'package:dena_pawna/features/installment/installment.dart';

/// কাস্টমারের কার্ড — তালিকা ও হোমের খোঁজে একই রকম।
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.highlighted = false,
    this.speaking = false,
  });
  final Customer customer;

  /// না দিলে কাস্টমারের খাতা খোলে।
  final VoidCallback? onTap;

  /// শোনার তালিকায় এখন যাকে পড়ছে — রঙিন বর্ডার, পড়ার সময় নামের পাশে স্পিকার।
  final bool highlighted, speaking;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final cs = Theme.of(context).colorScheme;

    final String subtitle;
    if (!c.hasDue) {
      subtitle = c.balance < 0
          ? LedgerText.of(c.direction).advance
          : '${LedgerText.of(c.direction).addTitle} নেই';
    } else if (c.onPlan) {
      final s = c.planStatus!;
      subtitle = s.behindCount > 0
          ? '${bn(s.behindCount)} কিস্তি পিছিয়ে • ${planNextLine(c)}'
          : planNextLine(c);
    } else if (c.dueDate != null) {
      subtitle = dueLabel(c.dueDate!, c.direction);
    } else {
      subtitle = 'তারিখ ঠিক হয়নি';
    }
    final reminderOn =
        c.hasDue &&
        c.reminderAt != null &&
        c.reminderAt!.isAfter(DateTime.now());

    return Card(
      clipBehavior: Clip.antiAlias,
      color: highlighted ? cs.primaryContainer.withValues(alpha: .45) : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: cs.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap ?? () => openCustomer(context, c.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              NameAvatar(c),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  // উচ্চতা বাঁধা জায়গায় (শোনার তালিকা) যেন পুরোটা না নেয়
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (speaking) ...[
                          Icon(
                            Icons.volume_up_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (c.hasDue && c.lastBakiAt != null)
                      Text(
                        lastBakiLabel(c),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    Row(
                      children: [
                        if (reminderOn) ...[
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: !c.hasDue
                                  ? cs.onSurfaceVariant
                                  : c.onPlan && c.planStatus!.behindCount > 0
                                  ? cs.error
                                  : dueColor(context, c.dueDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c.hasDue ? taka(c.balance) : '—',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.hasDue
                          ? ledgerAccent(
                              c.direction,
                              Theme.of(context).brightness,
                            )
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  if (c.hasDue)
                    Text(
                      c.direction == Ledger.debo ? 'দেব' : 'পাব',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
