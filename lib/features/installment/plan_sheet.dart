import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/installment/plan_labels.dart';

Future<void> showPlanSheet(BuildContext context, Customer c) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PlanSheet(customer: c),
    );

class PlanSheet extends StatefulWidget {
  const PlanSheet({super.key, required this.customer});
  final Customer customer;

  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  late final InstallmentPlan? _old = widget.customer.plan;
  late final _total = TextEditingController(
    text: _plain(_old?.total ?? widget.customer.balance.abs()),
  );
  late final _amount = TextEditingController(
    text: _old == null ? '' : _plain(_old.amount),
  );
  late int _every = _old?.every ?? 7;
  late DateTime _start = _old?.start ?? _nextFrom(today(), _every);

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// আজ থেকে এক কিস্তি পরের দিন — প্রথম কিস্তির ডিফল্ট।
  static DateTime _nextFrom(DateTime d, int every) => every == 0
      ? DateTime(d.year, d.month + 1, d.day)
      : DateTime(d.year, d.month, d.day + every);

  @override
  void dispose() {
    _total.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? get _totalV => parseAmount(_total.text);
  double? get _amountV => parseAmount(_amount.text);

  InstallmentPlan? get _plan {
    final total = _totalV, amount = _amountV;
    if (total == null || amount == null || total <= 0 || amount <= 0) {
      return null;
    }
    return InstallmentPlan(
      total: total,
      amount: math.min(amount, total),
      every: _every,
      start: _start,
      // বদলালে আগের জমাগুলো কিস্তিতে গোনা থাকে
      from: _old?.from ?? DateTime.now(),
    );
  }

  /// কয়েকটা কিস্তিতে ভাগ — ১০ টাকায় গোল করে।
  double _split(int n) => ((_totalV ?? 0) / n / 10).ceil() * 10.0;

  Future<void> _pickEvery() async {
    final ctrl = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('কত দিন পরপর?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯]')),
          ],
          decoration: const InputDecoration(
            hintText: 'যেমন ১০',
            suffixText: 'দিন',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(toEnDigits(ctrl.text))),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (days != null && days > 0) _setEvery(days);
  }

  void _setEvery(int every) => setState(() {
    _every = every;
    if (_old == null) _start = _nextFrom(today(), every);
  });

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: today().subtract(const Duration(days: 365)),
      lastDate: today().add(const Duration(days: 730)),
      helpText: 'প্রথম কিস্তির তারিখ',
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _save() async {
    final plan = _plan;
    if (plan == null) return toast(context, 'মোট আর কিস্তির টাকা লিখুন');
    await Store.instance.setPlan(widget.customer.id, plan);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    await Store.instance.setPlan(widget.customer.id, null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.customer;
    final plan = _plan;
    final label = TextStyle(
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );
    Widget money(TextEditingController ctrl, String hint) => TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯.]')),
      ],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(hintText: hint, prefixText: '৳ '),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _old == null
                  ? 'কিস্তিতে ${planVerb(c.direction)}'
                  : 'কিস্তি বদলান',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(c.name, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('মোট কত টাকা', style: label),
            const SizedBox(height: 8),
            money(_total, 'মোট'),
            const SizedBox(height: 16),
            Text('প্রতি কিস্তিতে কত', style: label),
            const SizedBox(height: 8),
            money(_amount, 'কিস্তির টাকা'),
            if ((_totalV ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in [3, 4, 6, 10])
                    if (_split(n) > 0)
                      ActionChip(
                        label: Text('${bn(n)} কিস্তি • ${taka(_split(n))}'),
                        onPressed: () =>
                            setState(() => _amount.text = _plain(_split(n))),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('কত দিন পরপর', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (every, text) in [
                  (7, 'প্রতি সপ্তাহে'),
                  (15, '১৫ দিন পরপর'),
                  (0, 'প্রতি মাসে'),
                ])
                  ChoiceChip(
                    label: Text(text),
                    selected: _every == every,
                    onSelected: (_) => _setEvery(every),
                  ),
                ChoiceChip(
                  label: Text(
                    [7, 15, 0].contains(_every)
                        ? 'অন্য'
                        : planEveryLabel(_every),
                  ),
                  selected: ![7, 15, 0].contains(_every),
                  onSelected: (_) => _pickEvery(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(fmtDate(_start)),
              subtitle: const Text('প্রথম কিস্তির তারিখ'),
              trailing: const Text('বদলান'),
              onTap: _pickStart,
            ),
            if (plan != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bn(plan.count)}টি কিস্তি, ${planEveryLabel(plan.every)} '
                  '${taka(plan.amount)} করে • শেষ কিস্তি ${fmtDate(plan.end)}',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_old != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                      ),
                      onPressed: _remove,
                      child: const Text('কিস্তি বন্ধ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: plan == null ? null : _save,
                    child: const Text('সেভ করুন'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
