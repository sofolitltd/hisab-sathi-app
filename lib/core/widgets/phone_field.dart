import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/utils/utils.dart';

/// মোবাইল নম্বরের ঘর — পাশে ফোনের কন্টাক্ট থেকে নেওয়ার বোতাম।
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.hint = 'মোবাইল নম্বর',
  });
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.phone_outlined),
        suffixIcon: IconButton(
          tooltip: 'কন্টাক্ট থেকে নিন',
          icon: const Icon(Icons.contacts_outlined),
          onPressed: () async {
            final p = await pickContact();
            if (p != null) controller.text = p.phone;
          },
        ),
      ),
    );
  }
}
