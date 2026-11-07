import 'package:flutter/material.dart';

/// শিটের মাথা — দিকের আইকন, শিরোনাম, কার নামে, আর বন্ধ বোতাম।
class EntrySheetHeader extends StatelessWidget {
  const EntrySheetHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isBaki,
  });
  final String title;
  final String? subtitle;
  final Color accent;
  final bool isBaki;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: accent.withValues(alpha: .12),
          child: Icon(
            isBaki ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'বন্ধ করুন',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
