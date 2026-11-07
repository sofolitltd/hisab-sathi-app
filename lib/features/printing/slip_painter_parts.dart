part of 'print_slips.dart';

/// স্টেটমেন্টের প্রতিটা অংশ আঁকা — কলামের মাথা, সারি, যোগফল, পাদটীকা।
extension _PainterParts on _StatementPainter {
  void _columnHead(Canvas canvas, double y) {
    canvas.drawRect(
      Rect.fromLTWH(_margin, y, _contentW, _colHeadH),
      Paint()..color = _ink,
    );
    void cell(String s, double x, double w, {bool right = false}) => _text(
      canvas,
      s,
      Offset(x + (right ? 0 : _pad), y + 5),
      width: w - _pad,
      size: 8.5,
      bold: true,
      color: Colors.white,
      align: right ? TextAlign.right : TextAlign.left,
    );
    cell('#', _margin, _cSl);
    cell('নাম', _xName, _cName);
    cell('মোবাইল', _xPhone, _cPhone);
    cell('শেষ এন্ট্রি', _xLast, _cLast);
    cell('দেওয়ার দিন', _xDue, _cDue);
    cell('টাকা', _xAmount, _cAmount, right: true);
    cell('ক্রমযোগ', _xRun, _cRun, right: true);
  }

  void _sectionTitle(Canvas canvas, double y, PrintSection s) {
    canvas.drawRect(
      Rect.fromLTWH(_margin, y, _contentW, _sectionH),
      Paint()..color = _band,
    );
    _text(
      canvas,
      s.title!,
      Offset(_margin + _pad, y + 5),
      size: 10,
      bold: true,
    );
    _text(
      canvas,
      '${bn(s.customers.length)} জন',
      Offset(_margin, y + 6),
      width: _contentW - _pad,
      size: 9,
      color: _muted,
      align: TextAlign.right,
    );
  }

  void _row(Canvas canvas, double y, int index, Customer c, double running) {
    if (index.isEven) {
      canvas.drawRect(
        Rect.fromLTWH(_margin, y, _contentW, _rowH),
        Paint()..color = _zebra,
      );
    }
    const size = 9.5;
    final ty = y + 4.5;
    void cell(
      String s,
      double x,
      double w, {
      bool right = false,
      bool bold = false,
      Color color = _ink,
    }) => _text(
      canvas,
      s,
      Offset(x + (right ? 0 : _pad), ty),
      width: w - _pad,
      size: size,
      bold: bold,
      color: color,
      align: right ? TextAlign.right : TextAlign.left,
    );
    final due = c.dueDate;
    cell(bn(index), _margin, _cSl, color: _muted);
    cell(c.name, _xName, _cName, bold: true);
    cell(
      c.phones.isNotEmpty ? c.phones.first : '—',
      _xPhone,
      _cPhone,
      color: _muted,
    );
    cell(
      c.lastBakiAt != null ? fmtShortDate(c.lastBakiAt!) : '—',
      _xLast,
      _cLast,
      color: _muted,
    );
    cell(
      due != null ? fmtShortDate(due) : '—',
      _xDue,
      _cDue,
      color: dueStatus(due) == DueStatus.overdue ? _late : _muted,
      bold: dueStatus(due) == DueStatus.overdue,
    );
    cell(taka(c.balance), _xAmount, _cAmount, right: true, bold: true);
    cell(taka(running), _xRun, _cRun, right: true, color: _muted);
  }

  void _subtotal(Canvas canvas, double y, PrintSection s) {
    _line(canvas, y, color: _muted);
    _text(
      canvas,
      'উপমোট — ${s.title}',
      Offset(_xName + _pad, y + 5),
      width: _xAmount - _xName - _pad,
      size: 9.5,
      bold: true,
      color: _muted,
    );
    _text(
      canvas,
      taka(s.sum),
      Offset(_xAmount, y + 5),
      width: _cAmount - _pad,
      size: 9.5,
      bold: true,
      align: TextAlign.right,
    );
  }

  /// শেষে দুই দাগের নিচে সর্বমোট — হিসাবের খাতার মতো।
  void _total(Canvas canvas, double y, int count, double sum) {
    _line(canvas, y + 4, color: _ink, w: 1);
    _line(canvas, y + 6.5, color: _ink, w: 1);
    _text(
      canvas,
      'সর্বমোট ${_t.name} — ${bn(count)} জন',
      Offset(_xName + _pad, y + 11),
      width: _xAmount - _xName - _pad,
      size: 11,
      bold: true,
    );
    _text(
      canvas,
      taka(sum),
      Offset(_xAmount - 20, y + 10),
      width: _cAmount + 20 - _pad,
      size: 12,
      bold: true,
      align: TextAlign.right,
    );
  }

  void _footer(Canvas canvas, int no, int total) {
    const y = _pageH - _margin - 14;
    _line(canvas, y - 4);
    _text(
      canvas,
      'হিসাব সাথী অ্যাপ থেকে তৈরি • এটি হিসাবের সারাংশ, আইনি দলিল নয়',
      const Offset(_margin, y),
      size: 8,
      color: _muted,
    );
    _text(
      canvas,
      'পৃষ্ঠা ${bn(no)} / ${bn(total)}',
      const Offset(_margin, y),
      size: 8,
      color: _muted,
      align: TextAlign.right,
    );
  }

  TextPainter _layout(
    String s, {
    double size = 10,
    bool bold = false,
    Color color = _ink,
    double width = double.infinity,
    TextAlign align = TextAlign.left,
  }) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: appFont,
        fontSize: size,
        height: 1.25,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '…',
  )..layout(minWidth: width.isFinite ? width : 0, maxWidth: width);

  /// এক লাইন লেখে, উচ্চতা ফেরত দেয়।
  double _text(
    Canvas canvas,
    String s,
    Offset at, {
    double size = 10,
    bool bold = false,
    Color color = _ink,
    double width = _contentW,
    TextAlign align = TextAlign.left,
  }) {
    final tp = _layout(
      s,
      size: size,
      bold: bold,
      color: color,
      width: width,
      align: align,
    );
    tp.paint(canvas, at);
    return tp.height;
  }
}
