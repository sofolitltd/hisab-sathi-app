import 'package:dena_pawna/core/utils/utils.dart';

const _w = [
  'শূন্য',
  'এক',
  'দুই',
  'তিন',
  'চার',
  'পাঁচ',
  'ছয়',
  'সাত',
  'আট',
  'নয়',
  'দশ',
  'এগারো',
  'বারো',
  'তেরো',
  'চৌদ্দ',
  'পনেরো',
  'ষোলো',
  'সতেরো',
  'আঠারো',
  'ঊনিশ',
  'বিশ',
  'একুশ',
  'বাইশ',
  'তেইশ',
  'চব্বিশ',
  'পঁচিশ',
  'ছাব্বিশ',
  'সাতাশ',
  'আটাশ',
  'ঊনত্রিশ',
  'ত্রিশ',
  'একত্রিশ',
  'বত্রিশ',
  'তেত্রিশ',
  'চৌত্রিশ',
  'পঁয়ত্রিশ',
  'ছত্রিশ',
  'সাঁইত্রিশ',
  'আটত্রিশ',
  'ঊনচল্লিশ',
  'চল্লিশ',
  'একচল্লিশ',
  'বিয়াল্লিশ',
  'তেতাল্লিশ',
  'চুয়াল্লিশ',
  'পঁয়তাল্লিশ',
  'ছেচল্লিশ',
  'সাতচল্লিশ',
  'আটচল্লিশ',
  'ঊনপঞ্চাশ',
  'পঞ্চাশ',
  'একান্ন',
  'বাহান্ন',
  'তিপ্পান্ন',
  'চুয়ান্ন',
  'পঞ্চান্ন',
  'ছাপ্পান্ন',
  'সাতান্ন',
  'আটান্ন',
  'ঊনষাট',
  'ষাট',
  'একষট্টি',
  'বাষট্টি',
  'তেষট্টি',
  'চৌষট্টি',
  'পঁয়ষট্টি',
  'ছেষট্টি',
  'সাতষট্টি',
  'আটষট্টি',
  'ঊনসত্তর',
  'সত্তর',
  'একাত্তর',
  'বাহাত্তর',
  'তিয়াত্তর',
  'চুয়াত্তর',
  'পঁচাত্তর',
  'ছিয়াত্তর',
  'সাতাত্তর',
  'আটাত্তর',
  'ঊনআশি',
  'আশি',
  'একাশি',
  'বিরাশি',
  'তিরাশি',
  'চুরাশি',
  'পঁচাশি',
  'ছিয়াশি',
  'সাতাশি',
  'আটাশি',
  'ঊননব্বই',
  'নব্বই',
  'একানব্বই',
  'বিরানব্বই',
  'তিরানব্বই',
  'চুরানব্বই',
  'পঁচানব্বই',
  'ছিয়ানব্বই',
  'সাতানব্বই',
  'আটানব্বই',
  'নিরানব্বই',
];

/// সংখ্যা → বাংলা কথা (যেমন ৪৫০০ → "চার হাজার পাঁচশো")। কোটি পর্যন্ত।
String banglaWords(int n) {
  if (n == 0) return _w[0];
  final parts = <String>[];
  var r = n;
  void unit(int size, String name) {
    final q = r ~/ size;
    if (q > 0) {
      parts.add('${banglaWords(q)} $name');
      r %= size;
    }
  }

  unit(10000000, 'কোটি');
  unit(100000, 'লক্ষ');
  unit(1000, 'হাজার');
  final h = r ~/ 100;
  if (h > 0) {
    parts.add('${_w[h]}শো');
    r %= 100;
  }
  if (r > 0) parts.add(_w[r]);
  return parts.join(' ');
}

/// টাকার অঙ্ক কথায়, পয়সা থাকলে সেটাও ("দুই হাজার টাকা পঞ্চাশ পয়সা")।
String takaWords(num amount) {
  final v = amount.abs();
  final whole = v.floor();
  final paisa = ((v - whole) * 100).round();
  final t = '${banglaWords(whole)} টাকা';
  return paisa > 0 ? '$t ${banglaWords(paisa)} পয়সা' : t;
}

// ---------- ভয়েস ইনপুট (বলে লেখা) ----------

const _unit = {'কোটি': 10000000, 'লক্ষ': 100000, 'লাখ': 100000, 'হাজার': 1000};

/// বলা কথা থেকে টাকার অঙ্ক: "৫০০", "500", "চার হাজার পাঁচশো", "দুই লাখ"। না বুঝলে null।
double? parseSpokenAmount(String text) {
  final t = toEnDigits(text).replaceAll(',', '');
  final digits = RegExp(r'\d+(\.\d+)?').firstMatch(t);
  if (digits != null) return double.tryParse(digits.group(0)!);

  final word = <String, int>{
    for (var i = 0; i < _w.length; i++) _w[i]: i,
    'দুই': 2,
    'দু': 2,
    'আঠার': 18,
    'ষোল': 16,
    'পনের': 15,
    'তের': 13,
    'বার': 12,
    'এগার': 11,
  };
  var total = 0, current = 0;
  var any = false;
  for (var tok in t.split(RegExp(r'\s+'))) {
    if (tok.isEmpty) continue;
    if (_unit.containsKey(tok)) {
      total += (current == 0 ? 1 : current) * _unit[tok]!;
      current = 0;
      any = true;
    } else if (tok == 'শো' || tok == 'শ') {
      current = (current == 0 ? 1 : current) * 100;
      any = true;
    } else if (tok.endsWith('শো') &&
        word.containsKey(tok.substring(0, tok.length - 2))) {
      current += word[tok.substring(0, tok.length - 2)]! * 100;
      any = true;
    } else if (word.containsKey(tok)) {
      current += word[tok]!;
      any = true;
    }
  }
  return any ? (total + current).toDouble() : null;
}
