import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/contact_log/contact_actions.dart';

/// পাশাপাশি তিনটা বাটনে কম প্যাডিং, যাতে লেখা জায়গা পায়।
final compactButtonStyle = ButtonStyle(
  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
);

/// আইকন আর লেখা এক লাইনে — জায়গা কম হলে ভাঙে না, একটু ছোট হয়ে যায়।
class OneLine extends StatelessWidget {
  const OneLine(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Text(label, maxLines: 1, softWrap: false),
      ],
    ),
  );
}

class LogTile extends StatelessWidget {
  const LogTile({super.key, required this.log, required this.onTap});
  final ContactLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: cs.primary.withValues(alpha: .1),
        child: Icon(contactIcon(log.kind), color: cs.primary, size: 20),
      ),
      title: Text(
        log.note.isEmpty
            ? contactLabel(log.kind)
            : '${contactLabel(log.kind)} — ${log.note}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${fmtDateTime(log.at)} • ${agoLabel(log.at)}'),
    );
  }
}
