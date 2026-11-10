import 'package:flutter/material.dart';

/// ক্যাটেগরির ঘর — সার্চ ফিল্ডের মতো, সরাসরি হাতে লেখা যায় অথবা ডান পাশের
/// সার্চ বাটনে চেপে তালিকা থেকে বাছাই/নতুন যোগ করা যায়।
class ExpenseCategoryField extends StatelessWidget {
  const ExpenseCategoryField({
    super.key,
    required this.controller,
    required this.recent,
  });

  final TextEditingController controller;
  final List<String> recent;

  Future<void> _search(BuildContext context) async {
    final c = await pickExpenseCategory(context, recent: recent);
    if (c != null && c.isNotEmpty) controller.text = c;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'ক্যাটেগরি (যেমন: দোকান ভাড়া, বাজার ব্যয়)',
        prefixIcon: const Icon(Icons.sell_outlined),
        suffixIcon: IconButton(
          tooltip: 'ক্যাটেগরি খুঁজুন',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => _search(context),
        ),
      ),
    );
  }
}

/// ক্যাটেগরি লিস্ট থেকে বাছাই (প্রোডাক্ট পিকারের মতোই) — না থাকলে এখান
/// থেকেই নতুন লেখা যায়।
Future<String?> pickExpenseCategory(
  BuildContext context, {
  required List<String> recent,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _ExpenseCategoryPicker(recent: recent),
);

class _ExpenseCategoryPicker extends StatefulWidget {
  const _ExpenseCategoryPicker({required this.recent});
  final List<String> recent;

  @override
  State<_ExpenseCategoryPicker> createState() =>
      _ExpenseCategoryPickerState();
}

class _ExpenseCategoryPickerState extends State<_ExpenseCategoryPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _all => widget.recent;

  List<String> _visible() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) => c.toLowerCase().contains(q)).toList();
  }

  Future<void> _addNew() async {
    final controller = TextEditingController(text: _search.text.trim());
    final typed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন ক্যাটেগরি'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'যেমন: মেরামত ব্যয়'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
    if (typed != null && typed.isNotEmpty && mounted) {
      Navigator.pop(context, typed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible();
    return DraggableScrollableSheet(
      initialChildSize: .7,
      minChildSize: .4,
      maxChildSize: .9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ক্যাটেগরি বাছুন',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addNew,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('নতুন'),
                ),
              ],
            ),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ক্যাটেগরি খুঁজুন',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('কোনো ক্যাটেগরি নেই'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        return ListTile(
                          leading: const Icon(Icons.sell_outlined),
                          title: Text(c),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
