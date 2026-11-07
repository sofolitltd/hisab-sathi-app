import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dena_pawna/core/config.dart';
import 'package:dena_pawna/core/photo/photo.dart';

/// সার্ভারের ফেরত দেওয়া ত্রুটি (বাংলা বার্তাসহ)।
class ApiError implements Exception {
  ApiError(this.message, {this.unauthorized = false});
  final String message;
  final bool unauthorized;
}

const offlineMsg = 'সার্ভারে কানেক্ট করা যায়নি। ইন্টারনেট দেখুন';

/// API-তে একটা JSON রিকুয়েস্ট। [token] দিলে Authorization হেডার যায়।
Future<Map<String, dynamic>> apiRequest(
  String method,
  String path, {
  Map<String, Object?>? body,
  String? token,
}) async {
  final authed = token != null;
  final req = http.Request(method, Uri.parse('$apiBase$path'));
  req.headers['Content-Type'] = 'application/json';
  if (authed) req.headers['Authorization'] = 'Bearer $token';
  if (body != null) req.body = jsonEncode(body);
  final res = await http.Response.fromStream(
    await req.send().timeout(const Duration(seconds: 25)),
  );
  final data = res.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode >= 200 && res.statusCode < 300) return data;
  throw ApiError(
    (data['error'] as String?) ?? 'সার্ভারে সমস্যা (${res.statusCode})',
    unauthorized: authed && res.statusCode == 401,
  );
}

// ---------- লোকাল রো → সার্ভারের JSON ----------

Future<Map<String, Object?>> customerJson(Map<String, Object?> r) async => {
  'uid': r['uid'],
  'ledger': r['ledger'],
  'name': r['name'],
  'phone': r['phone'],
  'extra_phones': r['extra_phones'],
  'plan': r['plan'],
  'address': r['address'],
  'photo': await photoToData(r['photo'] as String? ?? ''),
  'due_date': r['due_date'],
  'reminder_at': r['reminder_at'],
  'created_at': r['created_at'],
  'updated_at': r['updated_at'],
  'deleted': r['deleted'] == 1,
};

Map<String, Object?> entryJson(Map<String, Object?> r) => {
  'uid': r['uid'],
  'customer_uid': r['customer_uid'],
  'type': r['type'],
  'amount': r['amount'],
  'date': r['date'],
  'note': r['note'],
  'updated_at': r['updated_at'],
  'deleted': r['deleted'] == 1,
};

Map<String, Object?> logJson(Map<String, Object?> r) => {
  'uid': r['uid'],
  'customer_uid': r['customer_uid'],
  'kind': r['kind'],
  'note': r['note'],
  'at': r['at'],
  'updated_at': r['updated_at'],
  'deleted': r['deleted'] == 1,
};
