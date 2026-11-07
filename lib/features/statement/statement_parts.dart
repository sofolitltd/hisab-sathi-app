part of 'statement_image.dart';

// টেবিলের কলামের চওড়া।
const dateW = 78.0, amtW = 82.0, balW = 82.0;
const descW = _w - _pad * 2 - dateW - amtW - balW;

/// মোট বাকির বাক্স — টাকা, আর তারিখ বা কিস্তির লাইন। বাক্সের নিচের y ফেরত দেয়।
double _balanceBox(Canvas canvas, Customer c, LedgerText t, double y) {
  final box = Rect.fromLTWH(
    _pad,
    y,
    _w - _pad * 2,
    c.dueDate != null && c.hasDue ? 80 : 60,
  );
  final boxColor = c.hasDue ? bakiColor : jomaColor;
  canvas.drawRRect(
    RRect.fromRectAndRadius(box, const Radius.circular(12)),
    Paint()..color = boxColor.withValues(alpha: .08),
  );
  final label = c.hasDue
      ? 'মোট ${t.addTitle}'
      : c.balance < 0
      ? t.advance
      : 'কোনো ${t.addTitle} নেই';
  _text(
    canvas,
    label,
    Offset(box.left + 14, box.top + 12),
    size: 13,
    color: _muted,
  );
  if (c.hasDue || c.balance < 0) {
    _text(
      canvas,
      taka(c.balance),
      Offset(box.left, box.top + 6),
      width: box.width - 14,
      size: 24,
      bold: true,
      color: boxColor,
      align: TextAlign.right,
    );
  }
  if (c.dueDate != null && c.hasDue) {
    _text(
      canvas,
      c.onPlan
          ? 'কিস্তি: ${taka(c.plan!.amount)} ${planEveryLabel(c.plan!.every)} • '
                '${bn(c.planStatus!.paidCount)}/${bn(c.plan!.count)} দেওয়া • '
                'পরের: ${fmtShortDate(c.planStatus!.nextDate)}'
          : 'দেওয়ার কথা: ${fmtDate(c.dueDate!)} (${dueLabel(c.dueDate!, c.direction)})',
      Offset(box.left + 14, box.top + 48),
      width: box.width - 28,
      size: 12,
      color: switch (dueStatus(c.dueDate)) {
        DueStatus.overdue || DueStatus.today => bakiColor,
        _ => _ink,
      },
    );
  }
  return box.bottom;
}

/// টেবিলের এক সারি: তারিখ | বিবরণ | টাকা | বাকি।
void _cells(
  Canvas canvas,
  double y,
  String date,
  String desc,
  String amount,
  String bal, {
  bool bold = false,
  Color color = _ink,
  Color amountColor = _ink,
  double size = 11.5,
}) {
  var x = _pad + 6;
  _text(
    canvas,
    date,
    Offset(x, y),
    width: dateW - 6,
    size: size,
    bold: bold,
    color: color,
  );
  x = _pad + dateW;
  _text(
    canvas,
    desc,
    Offset(x, y),
    width: descW - 6,
    size: size,
    bold: bold,
    color: color,
  );
  x += descW;
  _text(
    canvas,
    amount,
    Offset(x, y),
    width: amtW - 6,
    size: size,
    bold: bold,
    color: amountColor,
    align: TextAlign.right,
  );
  x += amtW;
  _text(
    canvas,
    bal,
    Offset(x, y),
    width: balW - 6,
    size: size,
    bold: bold,
    color: color,
    align: TextAlign.right,
  );
}

/// এক লাইন লেখে (বেশি হলে …), উচ্চতা ফেরত দেয়।
double _text(
  Canvas canvas,
  String s,
  Offset at, {
  double size = 12,
  bool bold = false,
  Color color = _ink,
  double width = _w - _pad * 2,
  TextAlign align = TextAlign.left,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: appFont,
        fontSize: size,
        height: 1.3,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '…',
  )..layout(minWidth: width, maxWidth: width);
  tp.paint(canvas, at);
  return tp.height;
}
