import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/models.dart';
import 'package:dena_pawna/core/theme/theme.dart';
import 'package:dena_pawna/core/utils/utils.dart';
import 'package:dena_pawna/features/auth/auth_service.dart';
import 'package:dena_pawna/features/installment/installment.dart';

part 'statement_parts.dart';

/// ছবিতে সর্বোচ্চ কতটা লেনদেন — তার আগেরগুলো "আগের জের" হয়ে এক লাইনে।
const _maxRows = 60;

// মাপ লজিক্যাল পিক্সেলে; ছবি এর ৩ গুণ (১২০০ px চওড়া)।
const _w = 400.0, _pad = 20.0, _rowH = 26.0, _scale = 3.0;
const _ink = Color(0xFF111111), _muted = Color(0xFF666666);
const _brand = Color(0xFF0F766E);

/// একজন কাস্টমারের হিসাবের বিবরণ PNG ছবি হিসেবে — কাস্টমারকে পাঠানোর জন্য।
/// লেনদেন পুরোনো থেকে নতুন, পাশে প্রতিবারের পরের বাকি।
Future<Uint8List> renderStatement(Customer c, List<Entry> entries) async {
  final t = LedgerText.of(c.direction);
  final acc = AuthService.instance.account;
  final now = DateTime.now();

  final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
  double delta(Entry e) => e.type == EntryType.baki ? e.amount : -e.amount;
  final hidden = sorted.length > _maxRows
      ? sorted.take(sorted.length - _maxRows).toList()
      : <Entry>[];
  final shown = sorted.skip(hidden.length).toList();
  final opening = hidden.fold<double>(0, (s, e) => s + delta(e));

  final contact = [if (acc != null && acc.phone.isNotEmpty) acc.phone]
      .join(' • ');
  // ফোন না থাকলে ব্যান্ড ছোট
  final band = contact.isEmpty ? 66.0 : 92.0;

  final rows = hidden.length + shown.length == 0
      ? 1
      : shown.length + (hidden.isEmpty ? 0 : 1);
  final height =
      band +
      18 + // দোকানের ব্যান্ড
      (c.phones.isEmpty ? 56 : 74) + // কাস্টমার
      (c.dueDate != null && c.hasDue ? 96 : 76) + // বাকির বাক্স
      34 + // টেবিলের মাথা
      rows * _rowH +
      56; // ফুটার

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(_scale);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, _w, height),
    Paint()..color = Colors.white,
  );

  // ---- দোকান ----
  canvas.drawRect(Rect.fromLTWH(0, 0, _w, band), Paint()..color = _brand);
  var y = 18.0;
  final shop = 'হিসাব সাথী';
  y += _text(
    canvas,
    shop,
    Offset(_pad, y),
    size: 20,
    bold: true,
    color: Colors.white,
  );
  if (contact.isNotEmpty) {
    _text(
      canvas,
      contact,
      Offset(_pad, y + 2),
      size: 11,
      color: Colors.white70,
    );
  }
  y = band + 18;

  // ---- কাস্টমার ----
  y += _text(canvas, 'হিসাবের বিবরণ', Offset(_pad, y), size: 11, color: _muted);
  y += _text(canvas, c.name, Offset(_pad, y), size: 18, bold: true);
  if (c.phones.isNotEmpty) {
    y += _text(
      canvas,
      c.phones.join(', '),
      Offset(_pad, y),
      size: 11,
      color: _muted,
    );
  }
  y += 10;

  // ---- মোট বাকি ----
  y = _balanceBox(canvas, c, t, y) + 16;

  // ---- লেনদেনের টেবিল ----
  final headPaint = Paint()..color = const Color(0xFFF1F5F4);
  canvas.drawRect(Rect.fromLTWH(_pad, y, _w - _pad * 2, 26), headPaint);

  _cells(
    canvas,
    y + 5,
    'তারিখ',
    'বিবরণ',
    'টাকা',
    t.addTitle,
    bold: true,
    color: _muted,
    amountColor: _muted,
  );
  y += 34;

  var running = opening;
  if (hidden.isNotEmpty) {
    _cells(
      canvas,
      y + 4,
      '',
      'আগের ${bn(hidden.length)}টি লেনদেনের জের',
      '',
      taka(opening),
      color: _muted,
    );
    y += _rowH;
  }
  if (sorted.isEmpty) {
    _cells(canvas, y + 4, '', 'কোনো লেনদেন নেই', '', '', color: _muted);
    y += _rowH;
  }
  final line = Paint()
    ..color = const Color(0xFFE5E7EB)
    ..strokeWidth = .6;
  for (final e in shown) {
    running += delta(e);
    final isBaki = e.type == EntryType.baki;
    _cells(
      canvas,
      y + 4,
      fmtShortDate(e.date) +
          (e.date.year != now.year ? ' ${bn(e.date.year % 100)}' : ''),
      e.note.isNotEmpty ? e.note : entryWord(e.type),
      '${isBaki ? '+' : '−'} ${taka(e.amount)}',
      taka(running),
      amountColor: isBaki ? bakiColor : jomaColor,
    );
    y += _rowH;
    canvas.drawLine(Offset(_pad, y), Offset(_w - _pad, y), line);
  }

  // ---- ফুটার ----
  _text(
    canvas,
    'তৈরি: ${fmtDate(now)}, ${fmtTime(now.hour, now.minute)} • হিসাব সাথী অ্যাপ',
    Offset(_pad, height - 34),
    width: _w - _pad * 2,
    size: 10,
    color: _muted,
    align: TextAlign.center,
  );

  final image = await recorder.endRecording().toImage(
    (_w * _scale).round(),
    (height * _scale).round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
