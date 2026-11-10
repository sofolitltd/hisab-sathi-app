import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';
import 'package:hisab_sathi/features/profile/widgets/profile_avatar.dart';

/// প্রোফাইলের উপরের অংশ — লগইন না থাকলে অতিথির ছবি ও লেখা।
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.account});
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final acc = account;
    return acc == null ? _guestHeader(context) : _header(context, acc);
  }

  Widget _guestHeader(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(
            Icons.person_outline_rounded,
            size: 32,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'লগইন করা নেই',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'লোকাল খাতাই চলছে — নিচে লগইন করলে ব্যাকআপ/সিঙ্ক চালু হবে',
                style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, Account acc) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        ProfileAvatar(acc, radius: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acc.name,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                bn(acc.phone),
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
