import 'package:flutter/material.dart';

/// প্রতি ব্যক্তির জন্য একটাই সার্বজনীন signed ব্যালেন্স (`baki` বাড়ায়, `joma`
/// কমায়) — `Ledger` শুধু সেই sign-এর লাইভ প্রতিফলন, কোথাও স্টোর হয় না
/// (দেখুন `Customer.direction`):
///   pabo : balance পজিটিভ — আমি পাবো (তার কাছে পাওনা)
///   debo : balance নেগেটিভ — আমি দেবো (তার কাছে দেনা)
enum Ledger { pabo, debo }

class LedgerText {
  const LedgerText({
    required this.name,
    required this.party,
    required this.partyPlural,
    required this.partyHint,
    required this.total,
    required this.add,
    required this.reduce,
    required this.addShort,
    required this.reduceShort,
    required this.newEntry,
    required this.addSave,
    required this.reduceSave,
    required this.addTitle,
    required this.reduceTitle,
    required this.reduceWho,
    required this.whatHint,
    required this.whenAsk,
    required this.whenUnset,
    required this.hasDue,
    required this.dueToday,
    required this.dueTomorrow,
    required this.dueInDays,
    required this.added,
    required this.reduced,
    required this.reducedToday,
    required this.actToday,
    required this.rate,
    required this.biggest,
    required this.advance,
    required this.allSettled,
    required this.emptyHint,
  });

  final String name, party, partyPlural, partyHint, total;
  final String add, reduce, addShort, reduceShort, newEntry;
  final String addSave, reduceSave, addTitle, reduceTitle, reduceWho;
  final String whatHint, whenAsk, whenUnset, hasDue;
  final String dueToday, dueTomorrow, dueInDays;
  final String added, reduced, reducedToday, actToday, rate, biggest;
  final String advance, allSettled, emptyHint;

  static LedgerText of(Ledger l) => l == Ledger.pabo ? pabo : debo;

  static const pabo = LedgerText(
    name: 'পাওনা',
    party: 'ব্যক্তি',
    partyPlural: 'ব্যক্তি',
    partyHint: 'নাম লিখুন',
    total: 'মোট পাওনা',
    add: 'দিলাম',
    reduce: 'পেলাম',
    addShort: 'দিলাম',
    reduceShort: 'পেলাম',
    newEntry: 'নতুন এন্ট্রি',
    addSave: 'দিলাম সেভ করুন',
    reduceSave: 'পেলাম সেভ করুন',
    addTitle: 'পাওনা',
    reduceTitle: 'জমা',
    reduceWho: 'কার কাছ থেকে পেলেন?',
    whatHint: 'কী দিলেন? (ঐচ্ছিক)',
    whenAsk: 'কবে দেবে?',
    whenUnset: 'কবে দেবে ঠিক হয়নি',
    hasDue: 'পাওনা আছে',
    dueToday: 'আজ দেওয়ার কথা',
    dueTomorrow: 'আগামীকাল দেবে',
    dueInDays: 'দিন পর দেবে',
    added: 'নতুন পাওনা',
    reduced: 'আদায় হয়েছে',
    reducedToday: 'আজ আদায়',
    actToday: 'আজ আদায় করুন',
    rate: 'আদায়ের হার',
    biggest: 'সবচেয়ে বেশি পাওনা',
    advance: 'অগ্রিম জমা',
    allSettled: 'সব পাওনা আদায় হয়েছে ✓',
    emptyHint: 'নিচের "+" বাটনে চাপ দিয়ে প্রথম এন্ট্রি লিখুন',
  );

  static const debo = LedgerText(
    name: 'দেনা',
    party: 'ব্যক্তি',
    partyPlural: 'ব্যক্তি',
    partyHint: 'নাম লিখুন',
    total: 'মোট দেনা',
    add: 'দিলাম',
    reduce: 'পেলাম',
    addShort: 'দিলাম',
    reduceShort: 'পেলাম',
    newEntry: 'নতুন এন্ট্রি',
    addSave: 'দিলাম সেভ করুন',
    reduceSave: 'পেলাম সেভ করুন',
    addTitle: 'দেনা',
    reduceTitle: 'পরিশোধ',
    reduceWho: 'কার কাছ থেকে পেলেন?',
    whatHint: 'কী দিলেন? (ঐচ্ছিক)',
    whenAsk: 'কবে দেবেন?',
    whenUnset: 'কবে দেবেন ঠিক হয়নি',
    hasDue: 'দেনা আছে',
    dueToday: 'আজ দিতে হবে',
    dueTomorrow: 'আগামীকাল দিতে হবে',
    dueInDays: 'দিন পর দিতে হবে',
    added: 'নতুন দেনা',
    reduced: 'পরিশোধ করেছি',
    reducedToday: 'আজ পরিশোধ',
    actToday: 'আজ পরিশোধ করুন',
    rate: 'পরিশোধের হার',
    biggest: 'সবচেয়ে বেশি দেনা',
    advance: 'অগ্রিম দেওয়া',
    allSettled: 'সব দেনা শোধ হয়েছে ✓',
    emptyHint: 'নিচের "+" বাটনে চাপ দিয়ে প্রথম এন্ট্রি লিখুন',
  );
}

/// খাতার রঙ: পাওনা = টিল, দেনা = ইন্ডিগো।
Color ledgerAccent(Ledger l, Brightness b) => switch ((l, b)) {
  (Ledger.pabo, Brightness.light) => const Color(0xFF0F766E),
  (Ledger.pabo, Brightness.dark) => const Color(0xFF4DB6AC),
  (Ledger.debo, Brightness.light) => const Color(0xFF4338CA),
  (Ledger.debo, Brightness.dark) => const Color(0xFF8B8FF5),
};
