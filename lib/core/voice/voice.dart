import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/voice/bangla_numbers.dart';
import 'package:hisab_sathi/core/voice/phonetic.dart';

export 'package:hisab_sathi/core/voice/bangla_numbers.dart';
export 'package:hisab_sathi/core/voice/mic_button.dart';
export 'package:hisab_sathi/core/voice/phonetic.dart';

/// ফোনের নিজস্ব TTS দিয়ে পুরোটা বাংলা ভয়েসে পড়ে শোনায় — ইংরেজিতে লেখা নামও।
/// (নামগুলো ইংরেজি ভয়েসে পড়লে তালিকা শুনতে অদ্ভুত লাগে।)
/// ইন্টারনেট লাগে না (বাংলা ভয়েস ফোনে থাকলে)।
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  static const _languages = ['bn-BD', 'bn-IN', 'bn'];
  static const _googleEngine = 'com.google.android.tts';

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      var lang = await _banglaLanguage();
      // ফোনের ডিফল্ট ইঞ্জিনে (যেমন Samsung) বাংলা না থাকলে Google-এরটায় যাওয়া
      if (lang == null && defaultTargetPlatform == TargetPlatform.android) {
        final engines = await _tts.getEngines;
        if (engines is List && engines.contains(_googleEngine)) {
          await _tts.setEngine(_googleEngine);
          lang = await _banglaLanguage();
        }
      }
      if (lang == null) return false;
      await _tts.setLanguage(lang);
      await _pickBanglaVoice(lang);
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {
      return false;
    }
    return true;
  }

  Future<String?> _banglaLanguage() async {
    for (final l in _languages) {
      if (await _tts.isLanguageAvailable(l) == true) return l;
    }
    return null;
  }

  /// ইঞ্জিনের ডিফল্ট ভয়েস অনেক সময় বাংলা হয় না — নিজে বাংলা ভয়েস বাছাই,
  /// ঠিক লোকেলের আর অফলাইনেরটা আগে।
  Future<void> _pickBanglaVoice(String lang) async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      String locale(Map v) => '${v['locale']}'.replaceAll('_', '-');
      final bangla = [
        for (final v in voices)
          if (v is Map && locale(v).toLowerCase().startsWith('bn')) v,
      ];
      if (bangla.isEmpty) return;
      int score(Map v) =>
          (locale(v) == lang ? 2 : 0) + (v['network_required'] == '1' ? 0 : 1);
      bangla.sort((a, b) => score(b).compareTo(score(a)));
      final v = bangla.first;
      await _tts.setVoice({'name': '${v['name']}', 'locale': '${v['locale']}'});
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static const noVoiceMsg =
      'এই ফোনে বাংলা ভয়েস নেই। ফোনের সেটিংসে Google Text-to-speech-এ বাংলা ভয়েস ডাউনলোড করুন';

  /// পড়া শেষ হওয়া (বা থামানো) পর্যন্ত অপেক্ষা করে। বাংলা ভয়েস না থাকলে
  /// বা ত্রুটি হলে false।
  Future<bool> speak(String text) async {
    if (kIsWeb || !await _init()) return false;
    try {
      await _tts.speak(banglaForSpeech(text));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// পড়ে শোনায়। বাংলা ভয়েস না থাকলে বা ত্রুটি হলে বার্তা দেখায়।
  Future<void> say(BuildContext context, String text) async {
    if (kIsWeb) return;
    await stop();
    if (!await _init()) {
      if (context.mounted) toast(context, noVoiceMsg);
      return;
    }
    if (!await speak(text) && context.mounted) {
      toast(context, 'ভয়েস চালানো যায়নি');
    }
  }
}

/// একজন কাস্টমার/পাওনাদারের বাকির কথা।
String customerSpeech(Customer c) {
  final pabo = c.direction == Ledger.pabo;
  if (!c.hasDue) {
    return pabo
        ? '${c.name}-এর কাছে আপনার কোনো পাওনা নেই।'
        : '${c.name}-কে আপনার কোনো টাকা দিতে হবে না।';
  }
  final amount = takaWords(c.balance);
  final base = pabo
      ? '${c.name}-এর কাছে আপনার $amount পাওনা আছে।'
      : '${c.name}-কে আপনাকে $amount দিতে হবে।';
  if (c.dueDate == null) return base;
  final d = daysUntil(c.dueDate!);
  final when = d < 0
      ? 'মেয়াদ ${banglaWords(-d)} দিন আগে পার হয়ে গেছে।'
      : d == 0
      ? 'আজই ${pabo ? 'আদায়ের' : 'পরিশোধের'} দিন।'
      : '${banglaWords(d)} দিন পর ${pabo ? 'আদায়ের' : 'পরিশোধের'} মেয়াদ।';
  return '$base $when';
}

/// হোমের সারাংশ — পাওনা ও দেনা দুটোই একসাথে।
String summarySpeech({
  required double pabo,
  required double debo,
  required double overduePabo,
  required double overdueDebo,
  required double gotToday,
  required double gaveToday,
}) {
  if (pabo < 0.01 && debo < 0.01) return 'আপনার কোনো পাওনা-দেনা নেই।';
  final parts = <String>[
    if (pabo >= 0.01) 'মোট পাওনা ${takaWords(pabo)}।',
    if (overduePabo >= 0.01)
      'এর মধ্যে মেয়াদ পার হয়েছে ${takaWords(overduePabo)}।',
    if (debo >= 0.01) 'মোট দেনা ${takaWords(debo)}।',
    if (overdueDebo >= 0.01)
      'এর মধ্যে মেয়াদ পার হয়েছে ${takaWords(overdueDebo)}।',
    if (gotToday >= 0.01) 'আজ পেয়েছেন ${takaWords(gotToday)}।',
    if (gaveToday >= 0.01) 'আজ দিয়েছেন ${takaWords(gaveToday)}।',
  ];
  return parts.join(' ');
}
