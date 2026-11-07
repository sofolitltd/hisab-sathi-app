import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:hisab_sathi/core/utils/utils.dart';

/// মাইক বাটন: চাপলে শোনা শুরু, আবার চাপলে থামে। বলা কথা [onText]-এ আসে।
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.onText, this.onFinal, this.color});

  /// চলতি (আংশিক) ও শেষ ফলাফল।
  final ValueChanged<String> onText;

  /// শুধু শেষ ফলাফল।
  final ValueChanged<String>? onFinal;
  final Color? color;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  static final SpeechToText _stt = SpeechToText();
  static bool _inited = false;
  static String? _locale;
  bool _listening = false;

  Future<bool> _init() async {
    if (_inited) return true;
    try {
      final ok = await _stt.initialize(
        onStatus: (st) {
          if ((st == 'done' || st == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!ok) return false;
      final locales = await _stt.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().replaceAll('-', '_').startsWith('bn')) {
          _locale = l.localeId;
          if (_locale!.toLowerCase().endsWith('bd')) break;
        }
      }
      _inited = true;
    } catch (_) {
      return false;
    }
    return true;
  }

  Future<void> _toggle() async {
    if (kIsWeb) return;
    if (_listening) {
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!await _init()) {
      if (mounted) {
        toast(
          context,
          'ভয়েস ইনপুট চালু করা যায়নি। মাইক্রোফোনের অনুমতি ও Google ভয়েস সেবা দেখুন',
        );
      }
      return;
    }
    if (_locale == null && mounted) {
      toast(
        context,
        'বাংলা ভয়েস পাওয়া যায়নি, ফোনের ডিফল্ট ভাষায় শোনা হচ্ছে',
      );
    }
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (r) {
        widget.onText(r.recognizedWords);
        if (r.finalResult) widget.onFinal?.call(r.recognizedWords);
      },
    );
  }

  @override
  void dispose() {
    if (_listening) _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: _listening ? 'থামান' : 'বলে লিখুন',
      onPressed: _toggle,
      icon: Icon(
        _listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
        color: _listening ? cs.error : widget.color ?? cs.primary,
      ),
    );
  }
}
