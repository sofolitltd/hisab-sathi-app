import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/core/widgets/pin_field.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';
import 'package:dena_pawna/features/sync/sync_service.dart';

/// সিঙ্ক বাটন থেকে খোলা শিট: লগইন / সিঙ্কের অবস্থা।
void showSyncSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SyncSheet(),
  );
}

class _SyncSheet extends StatefulWidget {
  const _SyncSheet();

  @override
  State<_SyncSheet> createState() => _SyncSheetState();
}

class _SyncSheetState extends State<_SyncSheet> {
  final _sync = SyncService.instance;
  // অ্যাপে লগইন করা নম্বরই সার্ভারের নম্বর — আলাদা করে চাওয়া হয় না।
  late final String _phone =
      AuthService.instance.account?.phone ?? _sync.savedPhone ?? '';
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (_sync.loggedIn) return;
    // সংরক্ষিত PIN থাকলে নিজেই সংযোগ হয়; না হলে (PIN বদলে গেছে) PIN-এর ঘর।
    unawaited(_autoRetry());
  }

  Future<void> _autoRetry() async {
    setState(() => _busy = true);
    await _sync.retryConnect();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!_sync.loggedIn) _pinFocus.requestFocus();
  }

  @override
  void dispose() {
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    final msg = await _sync.connect(_phone, _pin.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _err = msg;
      if (msg != null) _pin.clear();
    });
    if (msg != null) _pinFocus.requestFocus();
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
      child: ListenableBuilder(
        listenable: _sync,
        builder: (context, _) => SingleChildScrollView(
          child: _sync.loggedIn ? _status(context) : _form(context),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ready = _phone.isNotEmpty && _pin.text.length == PinField.pinLength;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('অনলাইন ব্যাকআপ ও সিঙ্ক', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(
          'আপনি অ্যাপে ${bn(_phone)} নম্বরে লগইন করা আছেন। ব্যাকআপ চালু করতে '
          'শুধু PIN দিন। ইন্টারনেট না থাকলেও অ্যাপ আগের মতোই চলবে।',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 16),
        PinField(
          controller: _pin,
          focusNode: _pinFocus,
          onChanged: () => setState(() {}),
          onCompleted: _submit,
        ),
        if ((_err ?? _sync.error) != null) ...[
          const SizedBox(height: 10),
          Text((_err ?? _sync.error)!, style: TextStyle(color: cs.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || !ready ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('সংযোগ করুন'),
        ),
      ],
    );
  }

  static String _amPm(DateTime d) => bn(DateFormat('h:mm a', 'en').format(d));

  String _lastSyncText(DateTime? last) {
    if (last == null) return 'এখনো সিঙ্ক হয়নি';
    final days = today().difference(DateUtils.dateOnly(last)).inDays;
    final day = days == 0
        ? 'আজ'
        : days == 1
        ? 'গতকাল'
        : fmtDate(last);
    final counts = _sync.lastPushed == 0 && _sync.lastPulled == 0
        ? 'নতুন কিছু ছিল না'
        : 'পাঠানো ${bn(_sync.lastPushed)}টি · নামানো ${bn(_sync.lastPulled)}টি';
    return 'শেষ সিঙ্ক: $day, ${_amPm(last)}\n$counts';
  }

  Widget _status(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final last = _sync.lastSyncAt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('অনলাইন সিঙ্ক চালু', style: t.titleLarge),
        const SizedBox(height: 4),
        Text(_sync.phone ?? '', style: t.bodyMedium),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _sync.syncing
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _sync.error != null
                      ? Icons.error_outline_rounded
                      : Icons.cloud_done_rounded,
                  color: _sync.error != null ? cs.error : cs.primary,
                ),
          title: Text(
            _sync.syncing
                ? 'সিঙ্ক হচ্ছে...'
                : _sync.error ??
                      (_sync.pending > 0
                          ? 'পাঠানো হয়নি: ${_sync.pending}টি'
                          : 'সব ডাটা সিঙ্ক করা আছে'),
          ),
          isThreeLine: true,
          subtitle: Text(_lastSyncText(last)),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _sync.syncing ? null : _sync.syncNow,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('এখনই সিঙ্ক করুন'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _sync.syncing
              ? null
              : () async {
                  await _sync.logout();
                },
          child: const Text('লগআউট (এই ফোনের ডাটা থাকবে)'),
        ),
      ],
    );
  }
}
