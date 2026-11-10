import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/core/voice/voice.dart';

/// সারাংশ শোনানোর সময় কোন লাইনটা পড়ছে, তার visual indication — লাইনে
/// লাইনে হাইলাইট করে পড়ে, থামানো/আবার চালানো যায়। কাস্টমার লিস্টের
/// অডিও শিটের মতোই প্যাটার্ন।
Future<void> showSpeechSheet(BuildContext context, List<String> lines) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SpeechSheet(lines: lines),
    );

class _SpeechSheet extends StatefulWidget {
  const _SpeechSheet({required this.lines});
  final List<String> lines;

  @override
  State<_SpeechSheet> createState() => _SpeechSheetState();
}

class _SpeechSheetState extends State<_SpeechSheet> {
  int _i = 0;
  bool _playing = false;
  bool _finished = false;

  /// প্রতিবার চালানো/থামানোয় বাড়ে — পুরোনো লুপ বুঝে নিজে থেমে যায়।
  int _run = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _run++;
    Voice.instance.stop();
    super.dispose();
  }

  Future<void> _play() async {
    if (widget.lines.isEmpty) return;
    if (_finished) _i = 0;
    _finished = false;
    final run = ++_run;
    setState(() => _playing = true);
    while (true) {
      final ok = await Voice.instance.speak(widget.lines[_i]);
      if (!mounted || run != _run) return;
      if (!ok) {
        setState(() => _playing = false);
        toast(context, Voice.noVoiceMsg);
        return;
      }
      if (_i >= widget.lines.length - 1) {
        setState(() {
          _playing = false;
          _finished = true;
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted || run != _run) return;
      setState(() => _i++);
    }
  }

  void _pause() {
    _run++;
    Voice.instance.stop();
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.lines[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: i == _i && _playing ? 18 : 15,
                    fontWeight: i == _i && _playing
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: i == _i && _playing
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            IconButton.filled(
              tooltip: _playing ? 'থামান' : 'শুনুন',
              iconSize: 40,
              style: IconButton.styleFrom(fixedSize: const Size(68, 68)),
              onPressed: _playing ? _pause : _play,
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
