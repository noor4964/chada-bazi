import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const categories = <String>['পূজা / ঈদ', 'ক্লাব', 'বিল্ডিং / সার্ভিস চার্জ', 'চা-পানি', 'টোল / পার্কিং', 'অন্যান্য'];

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Money actually given as a donation, subscription, tip or toll.
class Contribution {
  final String id, category, to, note;
  final int amount;
  final DateTime date;
  const Contribution({
    required this.id,
    required this.amount,
    required this.category,
    required this.to,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'amount': amount, 'category': category, 'to': to, 'note': note, 'date': date.toIso8601String()};

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
        id: j['id'] as String,
        amount: j['amount'] as int,
        category: j['category'] as String,
        to: (j['to'] ?? '') as String,
        note: (j['note'] ?? '') as String,
        date: DateTime.parse(j['date'] as String),
      );
}

class Repayment {
  final DateTime date;
  final int amount;
  const Repayment(this.date, this.amount);

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'amount': amount};
  factory Repayment.fromJson(Map<String, dynamic> j) =>
      Repayment(DateTime.parse(j['date'] as String), j['amount'] as int);
}

/// A loan. [lent] is true when I gave the money, false when I borrowed it.
class Loan {
  final String id, person, note;
  final int amount;
  final bool lent;
  final DateTime created;
  final DateTime? due;
  final List<Repayment> repayments;

  Loan({
    required this.id,
    required this.person,
    required this.amount,
    required this.lent,
    required this.created,
    this.due,
    this.note = '',
    List<Repayment>? repayments,
  }) : repayments = repayments ?? [];

  int get repaid => repayments.fold(0, (s, r) => s + r.amount);
  int get remaining => (amount - repaid).clamp(0, amount);
  bool get settled => remaining == 0;
  bool isOverdue(DateTime now) => !settled && due != null && due!.isBefore(dayOnly(now));

  Map<String, dynamic> toJson() => {
        'id': id, 'person': person, 'amount': amount, 'lent': lent, 'note': note,
        'created': created.toIso8601String(), 'due': due?.toIso8601String(),
        'repayments': [for (final r in repayments) r.toJson()],
      };

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as String,
        person: j['person'] as String,
        amount: j['amount'] as int,
        lent: j['lent'] as bool,
        note: (j['note'] ?? '') as String,
        created: DateTime.parse(j['created'] as String),
        due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
        repayments: [for (final r in (j['repayments'] ?? const []) as List) Repayment.fromJson(r as Map<String, dynamic>)],
      );
}

/// On-device store. Screens only use this class, so the JSON backing can be
/// swapped for SQLite (drift) later without touching any UI.
class Ledger extends ChangeNotifier {
  static const _key = 'ledger1';
  final List<Contribution> contributions = [];
  final List<Loan> loans = [];
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      final j = jsonDecode(_p!.getString(_key) ?? '{}') as Map<String, dynamic>;
      importJson(j, notify: false);
    } catch (_) {}
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'contributions': [for (final c in contributions) c.toJson()],
        'loans': [for (final l in loans) l.toJson()],
      };

  /// Replaces all data with [j]. Used by load and by backup restore.
  void importJson(Map<String, dynamic> j, {bool notify = true}) {
    contributions
      ..clear()
      ..addAll([for (final c in (j['contributions'] ?? const []) as List) Contribution.fromJson(c as Map<String, dynamic>)]);
    loans
      ..clear()
      ..addAll([for (final l in (j['loans'] ?? const []) as List) Loan.fromJson(l as Map<String, dynamic>)]);
    contributions.sort((a, b) => b.date.compareTo(a.date));
    if (notify) _changed();
  }

  void _changed() {
    _p?.setString(_key, jsonEncode(toJson()));
    notifyListeners();
  }

  int _seq = 0;

  /// Timestamp plus a counter: the clock alone can repeat within one tick.
  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  void addContribution({required int amount, required String category, required String to, required DateTime date, String note = ''}) {
    contributions.add(Contribution(id: _id(), amount: amount, category: category, to: to, date: dayOnly(date), note: note));
    contributions.sort((a, b) => b.date.compareTo(a.date));
    _changed();
  }

  void removeContribution(String id) {
    contributions.removeWhere((c) => c.id == id);
    _changed();
  }

  /// Puts back a deleted entry (undo).
  void restoreContribution(Contribution c) {
    contributions
      ..add(c)
      ..sort((a, b) => b.date.compareTo(a.date));
    _changed();
  }

  void addLoan({required String person, required int amount, required bool lent, DateTime? due, String note = ''}) {
    loans.add(Loan(id: _id(), person: person, amount: amount, lent: lent, created: dayOnly(DateTime.now()), due: due == null ? null : dayOnly(due), note: note));
    _changed();
  }

  void addRepayment(String loanId, int amount, [DateTime? when]) {
    final l = loans.firstWhere((x) => x.id == loanId);
    if (l.remaining == 0) return;
    final pay = amount.clamp(1, l.remaining);
    l.repayments.add(Repayment(dayOnly(when ?? DateTime.now()), pay));
    _changed();
  }

  void removeLoan(String id) {
    loans.removeWhere((l) => l.id == id);
    _changed();
  }

  void clearAll() {
    contributions.clear();
    loans.clear();
    _changed();
  }

  // ------------------------------------------------------------ totals ---

  int monthTotal(DateTime m) =>
      contributions.where((c) => c.date.year == m.year && c.date.month == m.month).fold(0, (s, c) => s + c.amount);

  int yearTotal(int year) => contributions.where((c) => c.date.year == year).fold(0, (s, c) => s + c.amount);

  Map<String, int> byCategory(int year) {
    final m = <String, int>{};
    for (final c in contributions.where((c) => c.date.year == year)) {
      m[c.category] = (m[c.category] ?? 0) + c.amount;
    }
    return m;
  }

  /// Money others still owe me.
  int get owedToMe => loans.where((l) => l.lent).fold(0, (s, l) => s + l.remaining);

  /// Money I still owe others.
  int get iOwe => loans.where((l) => !l.lent).fold(0, (s, l) => s + l.remaining);

  int overdueCount(DateTime now) => loans.where((l) => l.isOverdue(now)).length;
}

final ledger = Ledger();
