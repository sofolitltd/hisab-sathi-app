import 'package:flutter/material.dart';

import 'package:hisab_sathi/features/sync/sync_button.dart';

/// উপরের বার — লোগো, অ্যাপের নাম আর সিঙ্ক বাটন। আগে এখানে পাওনা/দেনা মোড
/// সুইচ ছিল; সেটা সরানো হয়েছে যাতে প্রতিটা ট্যাব একটাই, সরাসরি লিস্ট দেখায়।
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.onProfileTap});

  /// লোগোতে চাপলে প্রোফাইল ট্যাবে যাওয়ার জন্য।
  final VoidCallback onProfileTap;

  static const _logo = 30.0;
  static const _radius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 2),
      child: Row(
        children: [
          Tooltip(
            message: 'প্রোফাইল',
            child: InkWell(
              borderRadius: BorderRadius.circular(_radius),
              onTap: onProfileTap,
              child: Image.asset(
                'assets/logo/logo_256.png',
                width: _logo,
                height: _logo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'হিসাব সাথী',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SyncButton(size: 36),
        ],
      ),
    );
  }
}
