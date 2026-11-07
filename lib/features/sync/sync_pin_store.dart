import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// সার্ভারের সংযোগের জন্য PIN ফোনের সুরক্ষিত স্টোরে (Keychain/Keystore) থাকে,
/// যাতে টোকেন না থাকলে বা মেয়াদ শেষ হলে ব্যবহারকারীকে আবার PIN দিতে না হয়।
abstract final class SyncPinStore {
  static const _secure = FlutterSecureStorage();
  static const _kPin = 'sync_pin';

  static Future<String?> read() => _secure.read(key: _kPin);

  static Future<void> save(String pin) async {
    try {
      await _secure.write(key: _kPin, value: pin);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await _secure.delete(key: _kPin);
    } catch (_) {}
  }
}
