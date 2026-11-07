import 'package:dena_pawna/core/models/model_utils.dart';

/// কাস্টমারের সাথে যোগাযোগের ধরন। `due` = "কবে দেবে" তারিখ বদল, নিজে থেকে লেখা হয়।
/// পুরোনো অ্যাপ অচেনা ধরনকে note হিসেবে পড়ে, তাই নোটের লেখা নিজেই বোঝা যায়।
enum ContactKind { call, sms, visit, note, due }

/// কবে কল/মেসেজ/সরাসরি তাগাদা দেওয়া হলো — সাথে কী বলল তার নোট।
class ContactLog {
  final int id;
  final int customerId;
  final ContactKind kind;
  final String note;
  final DateTime at;

  const ContactLog({
    required this.id,
    required this.customerId,
    required this.kind,
    this.note = '',
    required this.at,
  });

  factory ContactLog.fromMap(Map<String, Object?> m) => ContactLog(
    id: m['id'] as int,
    customerId: m['customer_id'] as int,
    kind: ContactKind.values.asNameMap()[m['kind']] ?? ContactKind.note,
    note: (m['note'] as String?) ?? '',
    at: dateFromMillis(m['at'])!,
  );
}
