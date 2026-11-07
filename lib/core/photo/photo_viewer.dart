import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/photo/photo.dart';

/// ছবি বড় করে ডায়লগে; যেকোনো জায়গায় চাপলে বন্ধ।
Future<void> showPhoto(BuildContext context, Customer c) => showDialog<void>(
  context: context,
  builder: (ctx) => Dialog(
    clipBehavior: Clip.antiAlias,
    insetPadding: const EdgeInsets.all(24),
    child: InkWell(
      onTap: () => Navigator.pop(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image(image: photoProvider(c.photo), fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  ),
);
