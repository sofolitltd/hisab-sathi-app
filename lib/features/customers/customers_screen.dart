import 'package:flutter/material.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/voice/voice.dart';
import 'package:dena_pawna/features/customer_detail/customer_form.dart';
import 'package:dena_pawna/features/customer_detail/customer_navigation.dart';
import 'package:dena_pawna/features/customers/audio_list_sheet.dart';
import 'package:dena_pawna/features/customers/customer_filters.dart';
import 'package:dena_pawna/features/customers/widgets/customer_card.dart';
import 'package:dena_pawna/features/customers/widgets/empty_state.dart';
import 'package:dena_pawna/features/customers/widgets/pabo_debo_total.dart';
import 'package:dena_pawna/features/printing/print_sheet.dart';

/// সব কাস্টমারের তালিকা — খোঁজা ও ফিল্টার।
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _store = Store.instance;
  final _search = TextEditingController();
  CustomerFilter _filter = CustomerFilter.all;
  CustomerSort _sort = CustomerSort.recent;
  Ledger? _side;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Customer c, CustomerFilter f) => switch (f) {
    CustomerFilter.due => c.hasDue,
    CustomerFilter.overdue =>
      c.hasDue && dueStatus(c.dueDate) == DueStatus.overdue,
    CustomerFilter.today => c.hasDue && dueStatus(c.dueDate) == DueStatus.today,
    CustomerFilter.upcoming =>
      c.hasDue &&
          (dueStatus(c.dueDate) == DueStatus.soon ||
              dueStatus(c.dueDate) == DueStatus.later),
    CustomerFilter.plan => c.onPlan,
    CustomerFilter.planBehind => c.onPlan && c.planStatus!.behindCount > 0,
    CustomerFilter.paid => !c.hasDue,
    CustomerFilter.all => true,
  };

  List<Customer> _visible() {
    final q = toEnDigits(_search.text.trim().toLowerCase());
    final list = _store.customers.where((c) {
      if (q.isNotEmpty) {
        return c.name.toLowerCase().contains(q) ||
            c.phones.any((p) => p.contains(q));
      }
      return _matches(c, _filter);
    }).toList();

    int recent(Customer a, Customer b) =>
        (b.lastEntryAt ?? b.createdAt).compareTo(a.lastEntryAt ?? a.createdAt);
    list.sort(
      (a, b) => switch (_sort) {
        CustomerSort.recent => recent(a, b),
        CustomerSort.high => b.balance.abs().compareTo(a.balance.abs()),
        CustomerSort.low => a.balance.abs().compareTo(b.balance.abs()),
      },
    );
    return list;
  }

  Future<void> _pickFilter() async {
    final f = await showModalBottomSheet<CustomerFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetLabel(ctx, 'সাজানো'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  // ক্রম বদলালে শিট খোলা থাকে, যাতে ফিল্টারও বাছাই করা যায়
                  child: SegmentedButton<CustomerSort>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: CustomerSort.recent,
                        label: Text('সাম্প্রতিক'),
                      ),
                      ButtonSegment(
                        value: CustomerSort.high,
                        icon: Icon(Icons.south_rounded, size: 16),
                        label: Text('টাকা বেশি'),
                      ),
                      ButtonSegment(
                        value: CustomerSort.low,
                        icon: Icon(Icons.north_rounded, size: 16),
                        label: Text('টাকা কম'),
                      ),
                    ],
                    selected: {_sort},
                    onSelectionChanged: (v) {
                      setState(() => _sort = v.first);
                      setSheet(() {});
                    },
                  ),
                ),
                _sheetLabel(ctx, 'ফিল্টার'),
                for (final f in CustomerFilter.values)
                  ListTile(
                    leading: Icon(
                      f == _filter
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: f == _filter
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                    ),
                    title: Text(filterLabel(f)),
                    trailing: Text(
                      bn(_store.customers.where((c) => _matches(c, f)).length),
                    ),
                    onTap: () => Navigator.pop(ctx, f),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (f != null) setState(() => _filter = f);
  }

  Widget _sheetLabel(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final all = _visible();
        final (pabo, debo) = paboDebo(all);
        final list = all.where((c) => matchesSide(c, _side)).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('ব্যক্তি'),
            actions: [
              IconButton(
                tooltip: 'তালিকা শুনুন',
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: list.isEmpty
                    ? null
                    : () => showAudioListSheet(context, list),
              ),
              IconButton(
                tooltip: 'তালিকা প্রিন্ট',
                icon: const Icon(Icons.print_outlined),
                onPressed: () => showPrintSheet(context),
              ),
              IconButton(
                tooltip: 'নতুন ব্যক্তি',
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () async {
                  final id = await showCustomerForm(context);
                  if (id != null && context.mounted) openCustomer(context, id);
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'নাম বা মোবাইল দিয়ে খুঁজুন',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? MicButton(
                                    onText: (t) => setState(() {
                                      _search.text = t;
                                      _search.selection =
                                          TextSelection.collapsed(
                                            offset: t.length,
                                          );
                                    }),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () =>
                                        setState(() => _search.clear()),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible:
                            _filter != CustomerFilter.all ||
                            _sort != CustomerSort.recent,
                        smallSize: 10,
                        child: IconButton.filledTonal(
                          tooltip: 'ফিল্টার',
                          style: IconButton.styleFrom(
                            fixedSize: const Size(52, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _pickFilter,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (all.isNotEmpty && pabo + debo > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          [
                            if (_search.text.isEmpty &&
                                _filter != CustomerFilter.all)
                              filterLabel(_filter),
                            if (_sort == CustomerSort.high) 'বেশি টাকা আগে',
                            if (_sort == CustomerSort.low) 'কম টাকা আগে',
                            '${bn(list.length)} জন',
                          ].join(' • '),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        PaboDeboTotal(
                          pabo: pabo,
                          debo: debo,
                          selected: _side,
                          onSelect: (s) => setState(() => _side = s),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_store.loaded && list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: CustomersEmptyState(
                    isSearch: _search.text.isNotEmpty,
                    noCustomers: _store.customers.isEmpty,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => CustomerCard(customer: list[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
