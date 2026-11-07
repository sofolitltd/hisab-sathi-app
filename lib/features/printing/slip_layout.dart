part of 'print_slips.dart';

// পাতার মাপ, সারির ধরন ও পাতায় ভাগ করা।

const _pageW = 595.28, _pageH = 841.89, _margin = 32.0;
const _contentW = _pageW - _margin * 2;
const _headerH = 124.0, _colHeadH = 20.0, _rowH = 20.0;
const _sectionH = 22.0, _subtotalH = 22.0, _totalH = 30.0, _footerH = 26.0;

sealed class _Item {
  const _Item();
  double get height;
}

class _Header extends _Item {
  const _Header();
  @override
  double get height => _headerH;
}

/// কলাম-শিরোনাম — প্রতিটা পাতার শুরুতে আবার আঁকা হয়।
class _ColumnHead extends _Item {
  const _ColumnHead();
  @override
  double get height => _colHeadH;
}

class _SectionTitle extends _Item {
  const _SectionTitle(this.section);
  final PrintSection section;
  @override
  double get height => _sectionH;
}

class _Row extends _Item {
  const _Row(this.customer, this.index, this.running);
  final Customer customer;
  final int index;

  /// এই সারি পর্যন্ত মোট — ব্যাংক স্টেটমেন্টের চলতি ব্যালেন্সের মতো।
  final double running;
  @override
  double get height => _rowH;
}

class _Subtotal extends _Item {
  const _Subtotal(this.section);
  final PrintSection section;
  @override
  double get height => _subtotalH;
}

class _Total extends _Item {
  const _Total(this.count, this.sum);
  final int count;
  final double sum;
  @override
  double get height => _totalH;
}

typedef _Placed = ({_Item item, double y});

List<List<_Placed>> _paginate(List<PrintSection> sections) {
  final items = <_Item>[const _Header(), const _ColumnHead()];
  var sl = 0;
  var running = 0.0;
  final grouped = sections.length > 1 || sections.firstOrNull?.title != null;
  for (final s in sections) {
    if (s.title != null) items.add(_SectionTitle(s));
    for (final c in s.customers) {
      running += c.balance.abs();
      items.add(_Row(c, ++sl, running));
    }
    if (grouped && s.title != null) items.add(_Subtotal(s));
  }
  items.add(_Total(sl, running));

  const bottom = _pageH - _margin - _footerH;
  final pages = <List<_Placed>>[[]];
  var y = _margin;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    // মাসের শিরোনাম একা পাতার নিচে পড়ে না থেকে প্রথম সারির সাথে যায়
    final need =
        item.height +
        (item is _SectionTitle && i + 1 < items.length
            ? items[i + 1].height
            : 0);
    if (y + need > bottom && pages.last.isNotEmpty) {
      pages.add([(item: const _ColumnHead(), y: _margin)]);
      y = _margin + _colHeadH;
      i--;
      continue;
    }
    pages.last.add((item: item, y: y));
    y += item.height;
  }
  return pages;
}

// ---- আঁকা ----
