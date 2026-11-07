part of 'print_slips.dart';

/// পয়েন্ট থেকে পিক্সেল (~১৮০ DPI) — প্রিন্টে লেখা পরিষ্কার থাকে।
const _scale = 2.5;
const _ink = Color(0xFF111111);
const _muted = Color(0xFF5F6368);
const _rule = Color(0xFFD9D9D9);
const _band = Color(0xFFF1F3F4);
const _zebra = Color(0xFFF8F9FA);
const _late = Color(0xFFB3261E);

// কলাম: # | নাম | মোবাইল | শেষ এন্ট্রি | দেওয়ার দিন | টাকা | ক্রমযোগ
const _cSl = 24.0, _cPhone = 80.0, _cLast = 58.0, _cDue = 58.0;
const _cAmount = 72.0, _cRun = 76.0;
double get _cName =>
    _contentW - _cSl - _cPhone - _cLast - _cDue - _cAmount - _cRun;
double get _xName => _margin + _cSl;
double get _xPhone => _xName + _cName;
double get _xLast => _xPhone + _cPhone;
double get _xDue => _xLast + _cLast;
double get _xAmount => _xDue + _cDue;
double get _xRun => _xAmount + _cAmount;
const _pad = 5.0;

class _StatementPainter {
  _StatementPainter({
    required this.ledger,
    required this.group,
    required this.oldestFirst,
    required this.sections,
    required this.printedAt,
    required this.holder,
  });

  final Ledger ledger;
  final PrintGroup group;
  final bool oldestFirst;
  final List<PrintSection> sections;
  final DateTime printedAt;
  final Account? holder;

  LedgerText get _t => LedgerText.of(ledger);

  Future<Uint8List> render(List<_Placed> page, int no, int total) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_scale);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _pageW, _pageH),
      Paint()..color = Colors.white,
    );
    for (final (:item, :y) in page) {
      switch (item) {
        case _Header():
          _header(canvas, y);
        case _ColumnHead():
          _columnHead(canvas, y);
        case _SectionTitle(:final section):
          _sectionTitle(canvas, y, section);
        case _Row(:final customer, :final index, :final running):
          _row(canvas, y, index, customer, running);
        case _Subtotal(:final section):
          _subtotal(canvas, y, section);
        case _Total(:final count, :final sum):
          _total(canvas, y, count, sum);
      }
    }
    _footer(canvas, no, total);

    final image = await recorder.endRecording().toImage(
      (_pageW * _scale).round(),
      (_pageH * _scale).round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  void _line(Canvas canvas, double y, {Color color = _rule, double w = .6}) =>
      canvas.drawLine(
        Offset(_margin, y),
        Offset(_margin + _contentW, y),
        Paint()
          ..color = color
          ..strokeWidth = w,
      );

  /// উপরে অ্যাপের নাম ও স্টেটমেন্টের শিরোনাম, খাতাধারী, আর সারাংশের বাক্স।
  void _header(Canvas canvas, double y) {
    final all = sections.expand((s) => s.customers).toList();
    final sum = all.fold<double>(0, (s, c) => s + c.balance.abs());

    _text(
      canvas,
      'হিসাব সাথী',
      Offset(_margin, y),
      size: 17,
      bold: true,
      color: brand,
    );
    _text(
      canvas,
      'ব্যক্তিগত দেনা-পাওনার হিসাব',
      Offset(_margin, y + 24),
      size: 9,
      color: _muted,
    );
    _text(
      canvas,
      '${_t.name}র স্টেটমেন্ট',
      Offset(_margin, y + 2),
      size: 14,
      bold: true,
      align: TextAlign.right,
    );
    _text(
      canvas,
      'প্রিন্ট: ${fmtDate(printedAt)}, ${fmtTime(printedAt.hour, printedAt.minute)}',
      Offset(_margin, y + 24),
      size: 9,
      color: _muted,
      align: TextAlign.right,
    );
    _line(canvas, y + 42, color: _ink, w: 1.2);

    final h = holder;
    if (h != null) {
      _text(
        canvas,
        'খাতাধারী: ${h.name}  •  ${h.phone}',
        Offset(_margin, y + 50),
        size: 10.5,
        bold: true,
      );
    }

    // সারাংশের বাক্স — চার ঘর
    const boxY = 70.0, boxH = 42.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_margin, y + boxY, _contentW, boxH),
        const Radius.circular(4),
      ),
      Paint()..color = _band,
    );
    final order = switch (group) {
      PrintGroup.lastBaki =>
        'শেষ ${_t.addTitle}র মাস, ${oldestFirst ? 'পুরোনো' : 'নতুন'} আগে',
      PrintGroup.due =>
        'দেওয়ার দিনের মাস, ${oldestFirst ? 'আগেরটা' : 'পরেরটা'} আগে',
      PrintGroup.name => 'নাম অনুযায়ী',
    };
    final cells = [
      ('খাতা', _t.name),
      ('মোট ব্যক্তি', '${bn(all.length)} জন'),
      ('মোট ${_t.name}', taka(sum)),
      ('সাজানো', order),
    ];
    const widths = [0.16, 0.18, 0.24, 0.42];
    var x = _margin;
    for (var i = 0; i < cells.length; i++) {
      final w = _contentW * widths[i];
      _text(
        canvas,
        cells[i].$1,
        Offset(x + 10, y + boxY + 7),
        width: w - 14,
        size: 8.5,
        color: _muted,
      );
      _text(
        canvas,
        cells[i].$2,
        Offset(x + 10, y + boxY + 20),
        width: w - 14,
        size: i == 2 ? 12 : 10.5,
        bold: true,
      );
      x += w;
    }
  }
}
