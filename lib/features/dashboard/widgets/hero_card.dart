import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/voice/voice.dart';
import 'package:dena_pawna/features/customers/people_list_page.dart';

/// একসাথে পাওনা আর দেনা দুটোই দেখায় — আগে একবারে একটাই (সক্রিয় মোড অনুযায়ী)
/// দেখাতো, এখন কোনো গ্লোবাল মোড নেই তাই দুটোই পাশাপাশি।
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.pabo,
    required this.debo,
    required this.overduePabo,
    required this.overdueDebo,
    required this.gotToday,
    required this.gaveToday,
  });
  final double pabo, debo, overduePabo, overdueDebo, gotToday, gaveToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x470F766E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'সব মিলিয়ে',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Voice.instance.say(
                  context,
                  summarySpeech(
                    pabo: pabo,
                    debo: debo,
                    overduePabo: overduePabo,
                    overdueDebo: overdueDebo,
                    gotToday: gotToday,
                    gaveToday: gaveToday,
                  ),
                ),
                child: Tooltip(
                  message: 'শুনুন',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroTotal(
                  ledger: Ledger.pabo,
                  label: 'মোট পাওনা',
                  value: taka(pabo),
                  overdue: overduePabo,
                  color: const Color(0xFF5EEAD4),
                ),
              ),
              Container(width: 1, height: 42, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: _HeroTotal(
                  ledger: Ledger.debo,
                  label: 'মোট দেনা',
                  value: taka(debo),
                  overdue: overdueDebo,
                  color: const Color(0xFFC4B5FD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _HeroStat(
                  label: 'আজ পেলাম',
                  value: taka(gotToday),
                  icon: Icons.south_west_rounded,
                ),
                Container(width: 1, height: 34, color: Colors.white24),
                _HeroStat(
                  label: 'আজ দিলাম',
                  value: taka(gaveToday),
                  icon: Icons.north_east_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTotal extends StatelessWidget {
  const _HeroTotal({
    required this.ledger,
    required this.label,
    required this.value,
    required this.overdue,
    required this.color,
  });
  final Ledger ledger;
  final String label, value;
  final double overdue;
  final Color color;

  /// মোটে চাপলে সবার তালিকা, মেয়াদ পারে চাপলে শুধু মেয়াদ পার হওয়াদের।
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => openPeopleList(context, title: label, ledger: ledger),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: overdue < 0.01
            ? null
            : () => openPeopleList(
                context,
                title: 'মেয়াদ পার',
                ledger: ledger,
                test: (c) => dueStatus(c.dueDate) == DueStatus.overdue,
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            overdue >= 0.01
                ? 'মেয়াদ পার ${taka(overdue)} ›'
                : 'মেয়াদ পার নেই',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: overdue >= 0.01 ? const Color(0xFFFCD34D) : Colors.white60,
              fontSize: 12,
              fontWeight: overdue >= 0.01 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ],
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
