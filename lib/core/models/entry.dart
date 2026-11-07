import 'package:dena_pawna/core/ledger.dart';
import 'package:dena_pawna/core/models/model_utils.dart';

/// baki = দিলাম (balance বাড়ে), joma = পেলাম (balance কমে) — সব দিকের জন্য একই।
enum EntryType { baki, joma }

extension LedgerEntry on Ledger {
  /// কোন এন্ট্রিতে এই দিকের হিসাব বাড়ে: পাওনায় দিলাম, দেনায় পেলাম।
  EntryType get grows => this == Ledger.pabo ? EntryType.baki : EntryType.joma;

  /// কোন এন্ট্রিতে এই দিকের হিসাব কমে (আদায় / পরিশোধ)।
  EntryType get shrinks =>
      this == Ledger.pabo ? EntryType.joma : EntryType.baki;
}

class Entry {
  final int id;
  final int customerId;
  final EntryType type;
  final double amount;
  final DateTime date;
  final String note;

  const Entry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Entry.fromMap(Map<String, Object?> m) => Entry(
    id: m['id'] as int,
    customerId: m['customer_id'] as int,
    type: m['type'] == 'joma' ? EntryType.joma : EntryType.baki,
    amount: (m['amount'] as num).toDouble(),
    date: dateFromMillis(m['date'])!,
    note: (m['note'] as String?) ?? '',
  );
}
