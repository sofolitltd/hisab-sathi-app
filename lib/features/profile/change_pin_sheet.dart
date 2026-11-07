import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/widgets/pin_field.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';

class ChangePinSheet extends StatefulWidget {
  const ChangePinSheet({super.key});

  @override
  State<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<ChangePinSheet> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _oldFocus = FocusNode();
  final _newFocus = FocusNode();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    // সংখ্যার কীপ্যাড নিজে খোলে।
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oldFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _oldFocus.dispose();
    _newFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    final msg = await AuthService.instance.changePin(_old.text, _new.text);
    if (!mounted) return;
    if (msg != null) {
      setState(() {
        _busy = false;
        _err = msg;
        _new.clear();
      });
      _newFocus.requestFocus();
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PIN বদলানো হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PIN বদলান', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            PinField(
              label: 'বর্তমান PIN',
              controller: _old,
              focusNode: _oldFocus,
              onChanged: () => setState(() {}),
              onCompleted: _newFocus.requestFocus,
            ),
            const SizedBox(height: 12),
            PinField(
              label: 'নতুন PIN (${bn(PinField.pinLength)} ডিজিট)',
              controller: _new,
              focusNode: _newFocus,
              onChanged: () => setState(() {}),
              onCompleted: _save,
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(
                _err!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  _busy ||
                      _old.text.length != PinField.pinLength ||
                      _new.text.length != PinField.pinLength
                  ? null
                  : _save,
              child: const Text('বদলান'),
            ),
          ],
        ),
      ),
    );
  }
}
