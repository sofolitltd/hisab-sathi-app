import 'package:flutter/material.dart';

import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/features/contact_log/contact_actions.dart';
import 'package:dena_pawna/features/contact_log/log_sheet.dart';
import 'package:dena_pawna/features/contact_log/logs_loader.dart';
import 'package:dena_pawna/features/contact_log/widgets/log_widgets.dart';

/// একজন কাস্টমারের সব কল, মেসেজ, তাগাদা — নতুনটা উপরে।
class ContactHistoryPage extends StatefulWidget {
  const ContactHistoryPage({super.key, required this.customer});
  final Customer customer;

  @override
  State<ContactHistoryPage> createState() => _ContactHistoryPageState();
}

class _ContactHistoryPageState extends State<ContactHistoryPage>
    with LogsLoader {
  @override
  int get customerId => widget.customer.id;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.customer;
    final list = logs;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('যোগাযোগের ইতিহাস'),
            Text(
              c.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: compactButtonStyle,
                  onPressed: c.phones.isEmpty
                      ? null
                      : () => callAndLog(context, c),
                  child: const OneLine(Icons.call_rounded, 'কল'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: compactButtonStyle,
                  onPressed: c.phones.isEmpty
                      ? null
                      : () => smsAndLog(context, c),
                  child: const OneLine(Icons.sms_rounded, 'মেসেজ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: compactButtonStyle,
                  onPressed: () => showLogSheet(context, c),
                  child: const OneLine(Icons.add_rounded, 'যোগ করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: list == null
          ? const SizedBox.shrink()
          : list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: cs.primary.withValues(alpha: .5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'এখনো কোনো যোগাযোগ লেখা নেই',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'কল বা তাগাদা SMS দিলে নিজে থেকেই এখানে লেখা থাকবে। '
                      'সরাসরি তাগাদা দিলে "যোগ করুন" চেপে লিখে রাখুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 72),
                        LogTile(
                          log: list[i],
                          onTap: () => showLogSheet(context, c, log: list[i]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'এডিট বা মুছতে চাপুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}
