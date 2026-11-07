import 'package:flutter/material.dart';

import 'package:dena_pawna/features/customer_detail/customer_screen.dart';

/// কাস্টমার/পাওনাদারের পাতা খোলা।
void openCustomer(BuildContext context, int id) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CustomerScreen(id: id)),
  );
}
