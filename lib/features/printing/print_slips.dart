import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show Printing;

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/ledger.dart';
import 'package:hisab_sathi/core/models/models.dart';
import 'package:hisab_sathi/core/theme/theme.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/auth/auth_service.dart';

part 'slip_layout.dart';
part 'slip_painter.dart';
part 'slip_painter_parts.dart';

/// প্রিন্টে ব্যক্তিদের কীভাবে ভাগ করে সাজানো হবে।
enum PrintGroup { lastBaki, due, name }

/// একই মাসের মানুষরা এক ভাগে। নাম অনুযায়ী হলে শিরোনাম ছাড়া একটাই ভাগ।
class PrintSection {
  PrintSection(this.title, this.customers);
  final String? title;
  final List<Customer> customers;

  double get sum => customers.fold(0, (s, c) => s + c.balance.abs());
}

List<PrintSection> printSections(
  Ledger ledger,
  PrintGroup group,
  bool oldestFirst,
) {
  final list = Store.instance.all
      .where((c) => c.direction == ledger && c.hasDue)
      .toList();
  if (group == PrintGroup.name) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [PrintSection(null, list)];
  }

  DateTime? key(Customer c) =>
      group == PrintGroup.lastBaki ? c.lastBakiAt : c.dueDate;
  // তারিখ ছাড়া যারা, তারা সবার শেষে
  list.sort((a, b) {
    final (x, y) = (key(a), key(b));
    if (x == null || y == null) {
      if (x == y) return a.name.compareTo(b.name);
      return x == null ? 1 : -1;
    }
    return oldestFirst ? x.compareTo(y) : y.compareTo(x);
  });

  final sections = <PrintSection>[];
  String? last;
  for (final c in list) {
    final d = key(c);
    final title = d == null
        ? (group == PrintGroup.due ? 'তারিখ ঠিক হয়নি' : 'তারিখ নেই')
        : bn(DateFormat('MMMM yyyy', 'bn').format(d));
    if (title != last) {
      sections.add(PrintSection(title, []));
      last = title;
    }
    sections.last.customers.add(c);
  }
  return sections;
}

/// ব্যাংক স্টেটমেন্টের ধাঁচে তালিকা — উপরে খাতাধারী ও সারাংশ, নিচে সারি ধরে
/// নাম, মোবাইল, তারিখ, টাকা আর ক্রমযোগ, মাসের শেষে উপমোট, শেষে সর্বমোট।
/// ফোনের প্রিন্ট ডায়লগ খোলে, সেখান থেকে PDF হিসেবেও সেভ করা যায়।
///
/// pdf প্যাকেজ বাংলা যুক্তাক্ষর ঠিকমতো জোড়া দিতে পারে না, তাই প্রতিটা পাতা
/// Flutter-এর নিজস্ব টেক্সট ইঞ্জিনে ছবি হিসেবে এঁকে PDF-এ বসানো হয়।
Future<void> printStatement({
  required Ledger ledger,
  required PrintGroup group,
  required bool oldestFirst,
}) async {
  final sections = printSections(ledger, group, oldestFirst);
  final pngs = await renderStatementPages(sections, ledger, group, oldestFirst);
  final doc = pw.Document(title: '${LedgerText.of(ledger).name}র স্টেটমেন্ট');
  for (final png in pngs) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.fill),
        ),
      ),
    );
  }
  final bytes = await doc.save();
  await Printing.layoutPdf(
    name:
        'dena-pawna-${ledger.name}-'
        '${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    format: PdfPageFormat.a4,
    onLayout: (_) async => bytes,
  );
}

/// প্রতিটা A4 পাতা PNG হিসেবে।
@visibleForTesting
Future<List<Uint8List>> renderStatementPages(
  List<PrintSection> sections,
  Ledger ledger,
  PrintGroup group,
  bool oldestFirst,
) async {
  final pages = _paginate(sections);
  final painter = _StatementPainter(
    ledger: ledger,
    group: group,
    oldestFirst: oldestFirst,
    sections: sections,
    printedAt: DateTime.now(),
    holder: AuthService.instance.account,
  );
  return [
    for (var i = 0; i < pages.length; i++)
      await painter.render(pages[i], i + 1, pages.length),
  ];
}

// ---- পাতা ভাগ ----
// সব মাপ পয়েন্টে (A4 = ৫৯৫ × ৮৪২)।
