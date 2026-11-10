import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/purchase_sale/sale_detail_sheet.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/speech_sheet.dart';
import 'package:hisab_sathi/features/purchase_sale/widgets/total_card.dart';
import 'package:hisab_sathi/features/stats/widgets/period_range.dart';

/// আয়ের পুরো লিস্ট — উপরে সময়ভিত্তিক ফিল্টার (আজ/৭ দিন/মাস/বছর/সব সময়)।
/// এডিট করার জন্য ট্যাপ করা যায়। মাইক বাটনে চাপলে বাছাই করা সময়ের মোট
/// আয়/লাভ/বাকি আর কোন প্রোডাক্টগুলো বিক্রি হলো, একটা শিটে লাইন-বাই-লাইন
/// হাইলাইট করে শোনা যায় — কোনটা এখন পড়ছে, তা স্পষ্ট দেখা যায়।
class SaleHistoryScreen extends StatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  State<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends State<SaleHistoryScreen>
    with PeriodRange {
  List<Sale>? _list;

  @override
  void initState() {
    super.initState();
    onLoad();
  }

  @override
  void onLoad() {
    final (from, to) = range();
    () async {
      final list = await Store.instance.salesBetween(from, to);
      if (mounted) setState(() => _list = list);
    }();
  }

  double get _totalSales =>
      (_list ?? const []).fold(0.0, (s, e) => s + e.totalAmount);
  double get _totalProfit =>
      (_list ?? const []).fold(0.0, (s, e) => s + (e.profit ?? 0));
  double get _totalDue => (_list ?? const []).fold(0.0, (s, e) => s + e.due);

  Future<void> _speak() async {
    final list = _list ?? const [];
    if (list.isEmpty) return toast(context, 'এই সময়ে কোনো আয় হয়নি');

    final products = <String>{for (final s in list) s.productName}.toList();
    final parts = [
      'মোট আয় ${taka(_totalSales)} টাকা।',
      if (_totalProfit != 0) 'লাভ ${taka(_totalProfit)} টাকা।',
      if (_totalDue > 0.009) 'বাকি আছে ${taka(_totalDue)} টাকা।',
      if (products.isNotEmpty) 'বিক্রি হয়েছে: ${products.join(', ')}।',
    ];
    await showSpeechSheet(context, parts);
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    return Scaffold(
      appBar: AppBar(
        title: const Text('আয়ের বিস্তারিত'),
        actions: [
          IconButton(
            tooltip: 'শুনুন',
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: _speak,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => onLoad(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            buildFilter(),
            const SizedBox(height: 12),
            if (list == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TotalCard(label: 'মোট আয়', value: taka(_totalSales)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TotalCard(
                      label: 'মোট লাভ',
                      value: taka(_totalProfit),
                      color: jomaColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TotalCard(
                      label: 'মোট বাকি',
                      value: taka(_totalDue),
                      color: bakiColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('এই সময়ে কোনো আয় হয়নি')),
                )
              else
                for (final s in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(
                          s.productName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          [
                            fmtDateDMY(s.date),
                            fmtTimeAmPm(s.date.hour, s.date.minute),
                            'পরিমাণ ${bn(s.quantity)}',
                            if (s.customerId != null)
                              Store.instance.byId(s.customerId!)?.name ?? '',
                            if (s.profit != null)
                              s.profit! >= 0
                                  ? 'লাভ ${taka(s.profit!)}'
                                  : 'ক্ষতি ${taka(s.profit!)}',
                            if (s.due > 0.009) 'বাকি ${taka(s.due)}',
                          ].where((t) => t.isNotEmpty).join(' · '),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Text(
                          taka(s.totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () async {
                          await showSaleDetailSheet(context, s);
                          onLoad();
                        },
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
