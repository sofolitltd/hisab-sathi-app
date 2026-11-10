import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hisab_sathi/features/auth/auth_screen.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';
import 'package:hisab_sathi/features/sync/sync_service.dart';
import 'package:hisab_sathi/features/sync/sync_sheet.dart';

/// সিঙ্কের অবস্থা দেখানো ছোট ক্লাউড বাটন।
class SyncButton extends StatelessWidget {
  const SyncButton({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final s = SyncService.instance;
        final (icon, color) = !s.loggedIn
            ? (Icons.cloud_off_rounded, cs.onSurfaceVariant)
            : s.error != null
            ? (Icons.cloud_off_rounded, cs.error)
            : s.syncing
            ? (Icons.cloud_sync_rounded, cs.primary)
            : s.pending > 0
            ? (Icons.cloud_upload_rounded, cs.primary)
            : (Icons.cloud_done_rounded, cs.primary);
        return Tooltip(
          message: 'অনলাইন সিঙ্ক',
          child: InkWell(
            borderRadius: BorderRadius.circular(size * .25),
            onTap: () {
              // লগইন করা না থাকলে সরাসরি লগইন পেজে — ফোন/PIN আর এখানে
              // আলাদা করে চাওয়া হয় না। লগইন করা থাকলে সিঙ্ক শুরু ও শিটে অবস্থা।
              if (AuthService.instance.account == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                return;
              }
              unawaited(s.syncNow());
              showSyncSheet(context);
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: light ? Colors.white : cs.surfaceContainer,
                borderRadius: BorderRadius.circular(size * .25),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: .6),
                ),
              ),
              child: Icon(icon, color: color, size: size * .55),
            ),
          ),
        );
      },
    );
  }
}
