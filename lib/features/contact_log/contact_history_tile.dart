import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/contact_log/contact_actions.dart';
import 'package:dena_pawna/features/contact_log/contact_history_page.dart';
import 'package:dena_pawna/features/contact_log/logs_loader.dart';

/// কাস্টমার পাতায় এক লাইন — শেষ যোগাযোগ আর কতগুলো; চাপলে পুরো ইতিহাসের পাতা।
/// লেনদেনের তালিকা যেন নিচে চাপা না পড়ে, তাই এখানে পুরো তালিকা দেখানো হয় না।
class ContactHistoryTile extends StatefulWidget {
  const ContactHistoryTile({super.key, required this.customer});
  final Customer customer;

  @override
  State<ContactHistoryTile> createState() => _ContactHistoryTileState();
}

class _ContactHistoryTileState extends State<ContactHistoryTile>
    with LogsLoader {
  @override
  int get customerId => widget.customer.id;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final last = logs?.firstOrNull;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ContactHistoryPage(customer: widget.customer),
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: .1),
          child: Icon(Icons.history_rounded, color: cs.primary, size: 20),
        ),
        title: Text(
          logs == null || logs!.isEmpty
              ? 'যোগাযোগের ইতিহাস'
              : 'যোগাযোগের ইতিহাস (${bn(logs!.length)})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          last == null
              ? 'এখনো কোনো কল বা তাগাদা নেই'
              : 'শেষ: ${contactLabel(last.kind)}'
                    '${last.note.isEmpty ? '' : ' — ${last.note}'}'
                    ' • ${agoLabel(last.at)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

/// "কবে দেবে" লাইনের নিচে — কতবার তারিখ বদলানো হয়েছে; চাপলে পুরো ইতিহাস।
class DueChangeCount extends StatefulWidget {
  const DueChangeCount({super.key, required this.customer});
  final Customer customer;

  @override
  State<DueChangeCount> createState() => _DueChangeCountState();
}

class _DueChangeCountState extends State<DueChangeCount> with LogsLoader {
  @override
  int get customerId => widget.customer.id;

  @override
  Widget build(BuildContext context) {
    final n = logs?.where((l) => l.kind == ContactKind.due).length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ContactHistoryPage(customer: widget.customer),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 28, top: 2, bottom: 2),
        child: Text(
          'তারিখ ${bn(n)} বার বদলেছে • দেখুন',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
