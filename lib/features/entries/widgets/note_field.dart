import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/voice/voice.dart';

/// নোটের ঘর — মাইকে বললে আগের লেখার পরে যোগ হয়।
class NoteField extends StatelessWidget {
  const NoteField({super.key, required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.notes_rounded),
        suffixIcon: MicButton(
          onFinal: (t) {
            final cur = controller.text.trim();
            controller.text = cur.isEmpty ? t : '$cur $t';
          },
          onText: (_) {},
        ),
      ),
    );
  }
}
