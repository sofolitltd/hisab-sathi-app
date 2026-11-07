import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/theme/theme.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/customer_detail/customer_navigation.dart';

class RecentTile extends StatelessWidget {
  const RecentTile({super.key, required this.entry, required this.name});
  final Entry entry;
  final String name;

  @override
  Widget build(BuildContext context) {
    final isBaki = entry.type == EntryType.baki;
    final color = isBaki ? bakiColor : jomaColor;
    final when = DateUtils.isSameDay(entry.date, DateTime.now())
        ? 'আজ'
        : fmtShortDate(entry.date);
    return ListTile(
      onTap: () => openCustomer(context, entry.customerId),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isBaki ? Icons.north_east_rounded : Icons.south_west_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [when, if (entry.note.isNotEmpty) entry.note].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isBaki ? '+' : '-'} ${taka(entry.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}
