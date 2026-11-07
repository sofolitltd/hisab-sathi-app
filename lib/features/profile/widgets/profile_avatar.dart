import 'package:flutter/material.dart';

import 'package:dena_pawna/core/photo/photo.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';

/// ছবি থাকলে ছবি, নইলে নামের প্রথম অক্ষর।
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(this.acc, {super.key, required this.radius});
  final Account acc;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withValues(alpha: .14),
      backgroundImage: acc.photo.isEmpty ? null : photoProvider(acc.photo),
      child: acc.photo.isEmpty
          ? Text(
              acc.name.characters.first.toUpperCase(),
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                fontSize: radius * .8,
              ),
            )
          : null,
    );
  }
}
