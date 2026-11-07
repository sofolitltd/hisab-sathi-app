import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dena_pawna/core/database/store.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';
import 'package:dena_pawna/features/sync/sync_api.dart';
import 'package:dena_pawna/features/sync/sync_pin_store.dart';

/// লোকাল SQLite ↔ অনলাইন সার্ভার সিঙ্ক। অ্যাপ আগের মতো অফলাইনেই চলে;
/// ইন্টারনেট থাকলে `dirty` রেকর্ড পাঠায়, আর সার্ভারের নতুন পরিবর্তন নামায়।
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _kToken = 'sync_token';
  static const _kPhone = 'sync_phone';
  static const _kCursor = 'sync_cursor';
  static const _kLastAt = 'sync_last_at';
  static const _kLastPushed = 'sync_last_pushed';
  static const _kLastPulled = 'sync_last_pulled';

  /// সার্ভার যোগাযোগের ইতিহাস রাখতে পারে কি না (pull-এ `logs` এলে বোঝা যায়)।
  /// পুরোনো সার্ভারে পাঠালে চুপচাপ হারিয়ে যেত, তাই তার আগে পাঠানো হয় না।
  static const _kLogsOk = 'sync_logs_ok';
  static const _chunk = 200;

  late SharedPreferences _prefs;
  Timer? _debounce;
  bool _again = false;

  String? token;
  String? phone;
  bool syncing = false;
  String? error;
  DateTime? lastSyncAt;

  /// শেষ সফল সিঙ্কে কতগুলো রেকর্ড পাঠানো ও নামানো হয়েছে।
  int lastPushed = 0;
  int lastPulled = 0;
  int pending = 0;

  bool get loggedIn => token != null;
  int get _cursor => _prefs.getInt(_kCursor) ?? 0;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    token = _prefs.getString(_kToken);
    phone = _prefs.getString(_kPhone);
    final at = _prefs.getInt(_kLastAt);
    lastSyncAt = at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
    lastPushed = _prefs.getInt(_kLastPushed) ?? 0;
    lastPulled = _prefs.getInt(_kLastPulled) ?? 0;
    Store.instance.onLocalChange = schedule;
    pending = await Store.instance.pendingSyncCount();
    // ইন্টারনেট না থাকলে আবার চেষ্টার জন্য।
    Timer.periodic(const Duration(minutes: 2), (_) {
      if (!loggedIn) {
        retryConnect();
      } else if (pending > 0 || error != null) {
        syncNow();
      }
    });
    notifyListeners();
    if (loggedIn) {
      unawaited(syncNow());
    } else {
      unawaited(retryConnect());
    }
  }

  /// পরিবর্তনের একটু পরে একবারে সিঙ্ক (বারবার সেভে বারবার রিকুয়েস্ট এড়াতে)।
  void schedule() {
    pending++;
    notifyListeners();
    if (!loggedIn) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }

  /// সফল হলে null, নইলে বাংলা ত্রুটির বার্তা।
  Future<String?> login(String phone, String pin) =>
      _auth('/auth/login', phone, pin);

  Future<String?> register(String phone, String pin) =>
      _auth('/auth/register', phone, pin);

  static const _existsMsg = 'এই নম্বরে আগেই অ্যাকাউন্ট আছে';

  /// অ্যাপে লগইন করা নম্বর; সার্ভারে সংযোগের ফর্মে আগে থেকে বসে।
  String? hintPhone;
  String? get savedPhone => _prefs.getString(_kPhone) ?? hintPhone;

  /// অ্যাপের লগইনের পরে একই নম্বর ও PIN দিয়ে সার্ভারে সংযোগ: অ্যাকাউন্ট না থাকলে
  /// খোলে, থাকলে লগইন করে। ব্যর্থ হলে ত্রুটি দেখায় (অফলাইনে চুপচাপ পরে আবার চেষ্টা)।
  Future<String?> connect(String phone, String pin) async {
    hintPhone = phone;
    var err = await register(phone, pin);
    if (err == _existsMsg) err = await login(phone, pin);
    if (err == null) {
      await SyncPinStore.save(pin);
    } else if (err == offlineMsg) {
      // অফলাইনে PIN রেখে দেওয়া হয়, ইন্টারনেট এলে নিজে সংযোগ হবে।
      await SyncPinStore.save(pin);
    } else {
      // PIN ভুল/বদলে গেছে — পুরোনোটা রেখে লাভ নেই, নতুন করে চাওয়া হবে।
      await SyncPinStore.clear();
    }
    if (err != null) {
      error = err;
      notifyListeners();
    }
    return err;
  }

  bool _connecting = false;

  /// সংরক্ষিত PIN দিয়ে চুপচাপ সংযোগ (টোকেন না থাকলে বা মেয়াদ শেষ হলে)।
  /// PIN না থাকলে কিছু করে না — তখন শিটে PIN চাওয়া হয়।
  Future<void> retryConnect() async {
    if (loggedIn || _connecting || syncing) return;
    final ph = AuthService.instance.account?.phone ?? phone;
    if (ph == null) return;
    _connecting = true;
    try {
      final pin = await SyncPinStore.read();
      if (pin != null) await connect(ph, pin);
    } catch (_) {
    } finally {
      _connecting = false;
    }
  }

  /// সংযুক্ত থাকলে সার্ভারে PIN বদলায়। সংযুক্ত না থাকলে কিছু করে না।
  Future<String?> changePin(String oldPin, String newPin) async {
    if (!loggedIn) {
      await SyncPinStore.save(newPin);
      return null;
    }
    try {
      await _send(
        'POST',
        '/auth/change-pin',
        body: {'old_pin': oldPin, 'new_pin': newPin},
      );
      await SyncPinStore.save(newPin);
      return null;
    } on ApiError catch (e) {
      return e.message;
    } catch (_) {
      return 'PIN বদলাতে ইন্টারনেট লাগবে। ইন্টারনেট চালু করে আবার চেষ্টা করুন';
    }
  }

  Future<String?> _auth(String path, String phone, String pin) async {
    try {
      final res = await _send(
        'POST',
        path,
        body: {'phone': phone, 'pin': pin},
        authed: false,
      );
      final changedUser = _prefs.getString(_kPhone) != res['phone'];
      token = res['token'] as String;
      this.phone = res['phone'] as String;
      await _prefs.setString(_kToken, token!);
      await _prefs.setString(_kPhone, this.phone!);
      // নতুন অ্যাকাউন্ট হলে এই ফোনের সব ডাটা সেখানে যাবে, আর নতুন করে নামানো হবে।
      if (changedUser) {
        await _prefs.setInt(_kCursor, 0);
        await Store.instance.markAllDirty();
        pending = await Store.instance.pendingSyncCount();
      }
      error = null;
      notifyListeners();
      unawaited(syncNow());
      return null;
    } on ApiError catch (e) {
      return e.message;
    } catch (_) {
      return offlineMsg;
    }
  }

  /// লগআউট করলে এই ফোনের ডাটা মোছে না।
  Future<void> logout() async {
    _debounce?.cancel();
    token = null;
    error = null;
    lastSyncAt = null;
    lastPushed = lastPulled = 0;
    await SyncPinStore.clear();
    await _dropToken();
  }

  /// টোকেন ফেলে দেয়, কিন্তু সংরক্ষিত PIN রাখে (মেয়াদ শেষ হলে নিজে আবার লগইন)।
  Future<void> _dropToken() async {
    token = null;
    await _prefs.remove(_kToken);
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (!loggedIn) return;
    if (syncing) {
      _again = true;
      return;
    }
    syncing = true;
    error = null;
    notifyListeners();
    final store = Store.instance;
    try {
      final d = await store.dirtyRows();
      final cs = [for (final r in d.customers) await customerJson(r)];
      final es = d.entries.map(entryJson).toList();
      final logsOk = _prefs.getBool(_kLogsOk) ?? false;
      final ls = logsOk ? d.logs.map(logJson).toList() : const [];
      for (var i = 0; i < cs.length; i += _chunk) {
        await _send(
          'POST',
          '/sync/push',
          body: {'customers': cs.skip(i).take(_chunk).toList(), 'entries': []},
        );
      }
      for (var i = 0; i < es.length; i += _chunk) {
        await _send(
          'POST',
          '/sync/push',
          body: {'customers': [], 'entries': es.skip(i).take(_chunk).toList()},
        );
      }
      for (var i = 0; i < ls.length; i += _chunk) {
        await _send(
          'POST',
          '/sync/push',
          body: {
            'customers': [],
            'entries': [],
            'logs': ls.skip(i).take(_chunk).toList(),
          },
        );
      }
      await store.markPushed('customers', d.customers);
      await store.markPushed('entries', d.entries);
      if (logsOk) await store.markPushed('contact_logs', d.logs);

      final res = await _send('GET', '/sync/pull?since=$_cursor');
      final logs = (res['logs'] as List?) ?? const [];
      await store.applyRemote(
        res['customers'] as List,
        res['entries'] as List,
        logs,
      );
      await _prefs.setInt(_kCursor, res['cursor'] as int);
      if (!logsOk && res.containsKey('logs')) {
        // সার্ভার নতুন — জমে থাকা ইতিহাস পরের সিঙ্কেই যাবে
        await _prefs.setBool(_kLogsOk, true);
        _again = true;
      }
      lastSyncAt = DateTime.now();
      lastPushed = d.customers.length + d.entries.length + ls.length;
      lastPulled =
          (res['customers'] as List).length +
          (res['entries'] as List).length +
          logs.length;
      await _prefs.setInt(_kLastAt, lastSyncAt!.millisecondsSinceEpoch);
      await _prefs.setInt(_kLastPushed, lastPushed);
      await _prefs.setInt(_kLastPulled, lastPulled);
    } on ApiError catch (e) {
      error = e.message;
      if (e.unauthorized) {
        await _dropToken();
        unawaited(retryConnect());
      }
    } catch (_) {
      error = offlineMsg;
    } finally {
      syncing = false;
      pending = await store.pendingSyncCount();
      notifyListeners();
    }
    if (_again) {
      _again = false;
      unawaited(syncNow());
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authed = true,
  }) => apiRequest(method, path, body: body, token: authed ? token : null);
}
