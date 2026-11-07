import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/photo/photo.dart';
import 'package:dena_pawna/core/photo/photo_viewer.dart';

/// কাস্টমারের নামের প্রথম অক্ষর দিয়ে গোল অ্যাভাটার — নাম অনুযায়ী রঙ বদলায়।
class NameAvatar extends StatelessWidget {
  const NameAvatar(this.customer, {super.key, this.radius = 22});
  final Customer customer;
  final double radius;

  static const _palette = [
    Color(0xFF0F766E),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFF4D7C0F),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[customer.name.hashCode.abs() % _palette.length];
    if (customer.photo.isNotEmpty) {
      return Semantics(
        button: true,
        label: 'ছবি বড় করে দেখুন',
        child: GestureDetector(
          onTap: () => showPhoto(context, customer),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: color.withValues(alpha: .14),
            backgroundImage: ResizeImage(
              photoProvider(customer.photo),
              width: (radius * 2 * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: .14),
      child: Text(
        customer.name.characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * .8,
        ),
      ),
    );
  }
}
