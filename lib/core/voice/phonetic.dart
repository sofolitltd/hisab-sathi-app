// ---------- ইংরেজি অক্ষরের নাম → বাংলা অক্ষর (শুধু পড়ার জন্য) ----------

/// নামে প্রায়ই আসে এমন শব্দ, যেগুলো নিয়মে ঠিক আসে না।
const _phoneticWords = {
  'md': 'মোহাম্মদ',
  'mohammad': 'মোহাম্মদ',
  'muhammad': 'মুহাম্মদ',
  'mst': 'মোসাম্মৎ',
  'store': 'স্টোর',
  'stores': 'স্টোর',
  'shop': 'শপ',
  'traders': 'ট্রেডার্স',
  'enterprise': 'এন্টারপ্রাইজ',
  'bhai': 'ভাই',
  'uncle': 'আঙ্কেল',
  'aunty': 'আন্টি',
  'sir': 'স্যার',
  'madam': 'ম্যাডাম',
  'boss': 'বস',
  'new': 'নিউ',
  'and': 'অ্যান্ড',
};

const _consonants = {
  'chh': 'ছ',
  'kh': 'খ',
  'gh': 'ঘ',
  'ng': 'ং',
  'ch': 'চ',
  'jh': 'ঝ',
  'th': 'থ',
  'dh': 'ধ',
  'ph': 'ফ',
  'bh': 'ভ',
  'sh': 'শ',
  'k': 'ক',
  'g': 'গ',
  'c': 'ক',
  'j': 'জ',
  't': 'ত',
  'd': 'দ',
  'n': 'ন',
  'p': 'প',
  'f': 'ফ',
  'b': 'ব',
  'm': 'ম',
  'r': 'র',
  'l': 'ল',
  's': 'স',
  'h': 'হ',
  'z': 'জ',
  'x': 'ক্স',
  'v': 'ভ',
  'q': 'ক',
};

/// (স্বাধীন রূপ, কার)
const _vowels = {
  'ee': ('ঈ', 'ী'),
  'oo': ('উ', 'ু'),
  'ou': ('ঔ', 'ৌ'),
  'oi': ('ঐ', 'ৈ'),
  'ai': ('আই', 'াই'),
  'a': ('আ', 'া'),
  'i': ('ই', 'ি'),
  'u': ('উ', 'ু'),
  'e': ('এ', 'ে'),
  'o': ('ও', 'ো'),
};

String? _match(String w, int i, Map<String, Object> table) {
  for (var len = 3; len >= 1; len--) {
    if (i + len > w.length) continue;
    final k = w.substring(i, i + len);
    if (table.containsKey(k)) return k;
  }
  return null;
}

/// একটা ইংরেজি শব্দকে উচ্চারণ অনুযায়ী বাংলা অক্ষরে — Bablu → বাব্লু।
String _phoneticWord(String word) {
  final w = word.toLowerCase();
  final known = _phoneticWords[w];
  if (known != null) return known;
  final out = StringBuffer();
  // ব্যঞ্জনের পরে: পরের ব্যঞ্জনে যুক্তাক্ষর, পরের স্বরে কার
  var afterConsonant = false;
  // য়-এর পরে: পরের স্বরে কার, কিন্তু ব্যঞ্জনে যুক্তাক্ষর নয় (Rayhan → রায়হান)
  var afterYa = false;
  var i = 0;
  while (i < w.length) {
    final v = _match(w, i, _vowels);
    if (v != null) {
      final (alone, kar) = _vowels[v]!;
      out.write(afterConsonant || afterYa ? kar : alone);
      afterConsonant = afterYa = false;
      i += v.length;
      continue;
    }
    final ch = w[i];
    final nextIsVowel = i + 1 < w.length && _match(w, i + 1, _vowels) != null;
    if (ch == 'y' && afterConsonant) {
      out.write('্য'); // য-ফলা
      afterConsonant = false;
      afterYa = true;
      i++;
      continue;
    }
    if (ch == 'w' && afterConsonant && i > 0 && w[i - 1] == 's') {
      out.write('্ব'); // Swapan → স্বপন
      afterConsonant = false;
      afterYa = true;
      i++;
      continue;
    }
    if (ch == 'y' || ch == 'w') {
      // Wahid → ওয়াহিদ, Anwar → আনওয়ার, Jewel → জেওয়েল
      out.write(ch == 'w' && nextIsVowel ? 'ওয়' : (ch == 'w' ? 'ও' : 'য়'));
      afterConsonant = false;
      afterYa = ch == 'y' || nextIsVowel;
      i++;
      continue;
    }
    final c = _match(w, i, _consonants);
    if (c == null) {
      out.write(ch);
      afterConsonant = afterYa = false;
      i++;
      continue;
    }
    if (afterConsonant && c != 'ng') out.write('্'); // যুক্তাক্ষর
    out.write(_consonants[c]);
    afterConsonant = c != 'ng';
    afterYa = false;
    i += c.length;
  }
  return out.toString();
}

/// লেখার ভেতরের ইংরেজি শব্দগুলো বাংলা অক্ষরে, যাতে বাংলা ভয়েস ভেঙে না পড়ে।
String banglaForSpeech(String text) =>
    text.replaceAllMapped(RegExp(r'[A-Za-z]+'), (m) => _phoneticWord(m[0]!));
