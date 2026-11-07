import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hisab_sathi/core/voice/voice.dart';

/// বড় টাকার ঘর — বাংলা/ইংরেজি অঙ্ক, আর মাইকে বলে লেখা।
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.accent,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final Color accent;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]')),
      ],
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: accent,
      ),
      decoration: InputDecoration(
        hintText: 'টাকার পরিমাণ',
        hintStyle: const TextStyle(fontSize: 20),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '৳',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: MicButton(
          color: accent,
          onText: (t) {
            final v = parseSpokenAmount(t);
            if (v == null) return;
            controller.text = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
          },
        ),
      ),
    );
  }
}
