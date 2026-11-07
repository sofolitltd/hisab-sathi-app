import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/photo/photo.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/widgets/phone_field.dart';
import 'package:dena_pawna/features/customer_detail/widgets/customer_name_field.dart';

/// নতুন কাস্টমার যোগ বা এডিট। নতুন হলে id ফেরত দেয়।
Future<int?> showCustomerForm(BuildContext context, {Customer? customer}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CustomerForm(customer: customer),
    );

class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key, this.customer});
  final Customer? customer;

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _extra = [
    for (final p in widget.customer?.extraPhones ?? const <String>[])
      TextEditingController(text: p),
  ];
  late String _photo = widget.customer?.photo ?? '';
  bool _saved = false;
  final _nameFocus = FocusNode();

  bool get _isNew => widget.customer == null;

  /// আগে থেকে থাকা কাস্টমার বাছাই করলে নতুন না বানিয়ে তার পাতাই খোলে।
  void _openExisting(Customer c) => Navigator.pop(context, c.id);

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    for (final c in _extra) {
      c.dispose();
    }
    // সেভ না করে বের হলে নতুন তোলা ছবি মুছে ফেলা
    if (!_saved && _photo.isNotEmpty && _photo != widget.customer?.photo) {
      deletePhoto(_photo);
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ক্যামেরা দিয়ে ছবি তুলুন'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('গ্যালারি থেকে বাছাই'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_photo.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('ছবি সরান'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final previous = _photo;
    if (source == 'remove') {
      setState(() => _photo = '');
    } else {
      final path = await pickCompressedPhoto(context, source as ImageSource);
      if (path == null || !mounted) return;
      setState(() => _photo = path);
    }
    // আগের অসংরক্ষিত ছবি থাকলে মুছে ফেলা
    if (previous.isNotEmpty && previous != widget.customer?.photo) {
      deletePhoto(previous);
    }
  }

  List<String> get _phones => [_phone.text, for (final c in _extra) c.text];

  Widget _extraPhoneField(TextEditingController c) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextField(
      controller: c,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'আরেকটি নম্বর',
        prefixIcon: const Icon(Icons.phone_outlined),
        suffixIcon: IconButton(
          tooltip: 'নম্বরটি সরান',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => setState(() {
            _extra.remove(c);
            c.dispose();
          }),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return toast(context, 'নাম লিখুন');
    final store = Store.instance;
    final c = widget.customer;
    if (c == null) {
      final id = await store.addCustomer(
        name: _name.text,
        phones: _phones,
        address: _address.text,
        photo: _photo,
      );
      _saved = true;
      await store.refresh();
      if (mounted) Navigator.pop(context, id);
    } else {
      await store.updateCustomer(
        c.id,
        name: _name.text,
        phones: _phones,
        address: _address.text,
        photo: _photo,
      );
      _saved = true;
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isNew ? 'নতুন ব্যক্তি' : 'তথ্য এডিট',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'বন্ধ করুন',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      backgroundImage: _photo.isEmpty
                          ? null
                          : photoProvider(_photo),
                      child: _photo.isEmpty
                          ? const Icon(Icons.person_rounded, size: 44)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ছবি (ঐচ্ছিক)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            CustomerNameField(
              controller: _name,
              focusNode: _nameFocus,
              isNew: _isNew,
              onExisting: _openExisting,
            ),
            const SizedBox(height: 12),
            PhoneField(controller: _phone),
            for (final c in _extra) _extraPhoneField(c),
            if (_extra.length < maxExtraPhones)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _extra.add(TextEditingController())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('আরও নম্বর যোগ করুন'),
                ),
              )
            else
              const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(
                hintText: 'ঠিকানা (ঐচ্ছিক)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('সেভ করুন')),
          ],
        ),
      ),
    );
  }
}
