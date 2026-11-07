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
    return Column(
      children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 48,
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(
            Icons.person_outline_rounded,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'লগইন করা নেই',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'লোকাল খাতাই চলছে — নিচে লগইন করলে ব্যাকআপ/সিঙ্ক চালু হবে',
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, Account acc) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 8),
        ProfileAvatar(acc, radius: 48),
        const SizedBox(height: 12),
        Text(
          acc.name,
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          bn(acc.phone),
          style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
