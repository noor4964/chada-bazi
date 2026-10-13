import 'package:flutter_test/flutter_test.dart';

import 'package:chada_bazar/ledger.dart';

void main() {
  test('contribution totals by month, year and category', () {
    final l = Ledger();
    l.addContribution(amount: 500, category: 'ক্লাব', to: 'ক্লাব', date: DateTime(2026, 3, 5));
    l.addContribution(amount: 200, category: 'চা-পানি', to: '', date: DateTime(2026, 3, 20));
    l.addContribution(amount: 1000, category: 'ক্লাব', to: '', date: DateTime(2026, 4, 1));
    l.addContribution(amount: 300, category: 'ক্লাব', to: '', date: DateTime(2025, 12, 31));
    expect(l.monthTotal(DateTime(2026, 3, 1)), 700);
    expect(l.yearTotal(2026), 1700);
    expect(l.byCategory(2026)['ক্লাব'], 1500);
    expect(l.contributions.first.date, DateTime(2026, 4, 1)); // newest first
  });

  test('loans: repayments, overdue and totals', () {
    final l = Ledger();
    l.addLoan(person: 'সাকিব', amount: 2000, lent: true, due: DateTime(2020, 1, 1));
    l.addLoan(person: 'রাফি', amount: 800, lent: false);
    expect(l.owedToMe, 2000);
    expect(l.iOwe, 800);
    expect(l.overdueCount(DateTime(2026, 1, 1)), 1);

    final id = l.loans.first.id;
    l.addRepayment(id, 500);
    l.addRepayment(id, 99999); // capped to what is left
    expect(l.loans.first.settled, isTrue);
    expect(l.loans.first.repaid, 2000);
    expect(l.owedToMe, 0);
    expect(l.overdueCount(DateTime(2026, 1, 1)), 0); // settled loans are never overdue
  });

  test('backup round trip keeps everything', () {
    final a = Ledger();
    a.addContribution(amount: 150, category: 'টোল / পার্কিং', to: 'গেট', date: DateTime(2026, 5, 2), note: 'রাত');
    a.addLoan(person: 'নিলয়', amount: 700, lent: true, due: DateTime(2026, 6, 1));
    a.addRepayment(a.loans.first.id, 200);

    final b = Ledger()..importJson(a.toJson());
    expect(b.contributions.single.note, 'রাত');
    expect(b.loans.single.remaining, 500);
    expect(b.loans.single.due, DateTime(2026, 6, 1));
  });

  test('restoreContribution puts a deleted entry back in order', () {
    final l = Ledger();
    l.addContribution(amount: 10, category: 'অন্যান্য', to: '', date: DateTime(2026, 1, 1));
    l.addContribution(amount: 20, category: 'অন্যান্য', to: '', date: DateTime(2026, 2, 1));
    final gone = l.contributions.first;
    l.removeContribution(gone.id);
    expect(l.contributions.length, 1);
    l.restoreContribution(gone);
    expect(l.contributions.first.amount, 20);
  });
}
