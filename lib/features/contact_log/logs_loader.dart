import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/models/models.dart';

/// ইতিহাস বদলালে নিজে থেকে আবার পড়ে নেয়।
mixin LogsLoader<T extends StatefulWidget> on State<T> {
  int get customerId;
  List<ContactLog>? logs;

  @override
  void initState() {
    super.initState();
    Store.instance.logsChanged.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    Store.instance.logsChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final l = await Store.instance.logsOf(customerId);
    if (mounted) setState(() => logs = l);
  }
}
