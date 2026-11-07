import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/theme/theme.dart';
import 'package:dena_pawna/core/utils/utils.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.text,
    required this.onTap,
  });
  final Entry entry;
  final LedgerText text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isBaki = e.type == EntryType.baki;
    final color = isBaki ? bakiColor : jomaColor;
    return ListTile(
      onTap: onTap,
      onLongPress: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(
          isBaki ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(e.note.isNotEmpty ? e.note : entryWord(e.type)),
      subtitle: Text(fmtDate(e.date)),
      trailing: Text(
        '${isBaki ? '+' : '−'} ${taka(e.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}
