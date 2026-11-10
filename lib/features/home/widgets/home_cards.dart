import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';

/// হোমের সেকশন শিরোনাম — ডানে ঐচ্ছিক ছোট লিংক ("সব দেখুন")।
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null)
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '$action ›',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
    ],
  );
}

/// মোট পাওনা, মোট দেনা আর নিট — সাদা কার্ড, রঙ শুধু সংখ্যায়।
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.pabo,
    required this.debo,
    required this.overduePabo,
    required this.overdueDebo,
    required this.onPabo,
    required this.onDebo,
  });
  final double pabo, debo, overduePabo, overdueDebo;
  final VoidCallback onPabo, onDebo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final net = pabo - debo;
    final netText = net.abs() < 0.01
        ? 'হিসাব সমান'
        : net > 0
        ? 'নিট পাওনা ${taka(net)}'
        : 'নিট দেনা ${taka(net)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Total(
                  label: 'মোট পাওনা',
                  value: taka(pabo),
                  overdue: overduePabo,
                  color: jomaColor,
                  onTap: onPabo,
                ),
                Container(
                  width: 1,
                  height: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: cs.outlineVariant,
                ),
                _Total(
                  label: 'মোট দেনা',
                  value: taka(debo),
                  overdue: overdueDebo,
                  color: bakiColor,
                  onTap: onDebo,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                netText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: net.abs() < 0.01
                      ? cs.onSurfaceVariant
                      : net > 0
                      ? jomaColor
                      : bakiColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.value,
    required this.overdue,
    required this.color,
    required this.onTap,
  });
  final String label, value;
  final double overdue;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              overdue >= 0.01 ? 'মেয়াদ পার ${taka(overdue)}' : 'মেয়াদ পার নেই',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: overdue >= 0.01
                    ? const Color(0xFFB45309)
                    : cs.onSurfaceVariant,
                fontWeight: overdue >= 0.01 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// গোল আইকন + নিচে লেবেল — চারটা পাশাপাশি সমান ভাগে।
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

/// আজকের আয়, ব্যয়, নিট লাভ — নিচে আজ পেলাম/দিলাম।
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.income,
    required this.expense,
    required this.net,
    required this.got,
    required this.gave,
  });
  final double income, expense, net, got, gave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _Stat('আয়', taka(income), saleColor),
                _Stat('ব্যয়', taka(expense), expenseColor),
                _Stat(
                  net < 0 ? 'নিট লোকসান' : 'নিট লাভ',
                  taka(net),
                  net < 0 ? bakiColor : cs.primary,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: .6),
              ),
            ),
            Row(
              children: [
                _Stat('আজ পেলাম', taka(got), jomaColor),
                _Stat('আজ দিলাম', taka(gave), bakiColor),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

/// "আজ করণীয়" — একটা লাইনের সতর্কতা, চাপলে দেনা-পাওনা ট্যাবে যায়।
class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.notifications_active_outlined,
          color: Color(0xFFB45309)),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('আদায়/পরিশোধ দেখুন'),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

/// রিপোর্টের ছোট শর্টকাট — আইকন + নাম, পাশাপাশি দুটো।
class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: reportColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
