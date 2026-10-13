import 'ledger.dart';

/// Year summary built from the real ledger.
class WrappedData {
  final int year, total, count, topAmount, peakMonth, peakAmount, owedToMe, iOwe, loanCount;
  final String topCategory;
  const WrappedData({
    required this.year,
    required this.total,
    required this.count,
    required this.topCategory,
    required this.topAmount,
    required this.peakMonth,
    required this.peakAmount,
    required this.owedToMe,
    required this.iOwe,
    required this.loanCount,
  });

  /// Share of the year's total that went to the top category, 0 to 100.
  int get topPercent => total == 0 ? 0 : (topAmount * 100 / total).round();

  int get average => count == 0 ? 0 : (total / count).round();

  /// How the ভাই sees you, based on how much you handed over.
  String get title {
    if (total >= 20000) return 'পাড়ার ATM';
    if (total >= 8000) return 'দানবীর হাতেম তাই';
    if (total >= 2000) return 'নিয়মিত দাতা';
    return 'নতুন ভিকটিম';
  }
}

/// Null when [l] has no contributions in [year].
WrappedData? buildWrapped(Ledger l, int year) {
  final list = l.contributions.where((c) => c.date.year == year).toList();
  if (list.isEmpty) return null;

  final byCat = l.byCategory(year);
  final top = byCat.entries.reduce((a, b) => b.value > a.value ? b : a);

  final byMonth = <int, int>{};
  for (final c in list) {
    byMonth[c.date.month] = (byMonth[c.date.month] ?? 0) + c.amount;
  }
  final peak = byMonth.entries.reduce((a, b) => b.value > a.value ? b : a);

  return WrappedData(
    year: year,
    total: l.yearTotal(year),
    count: list.length,
    topCategory: top.key,
    topAmount: top.value,
    peakMonth: peak.key,
    peakAmount: peak.value,
    owedToMe: l.owedToMe,
    iOwe: l.iOwe,
    loanCount: l.loans.length,
  );
}

/// A made-up year, shown as a preview before the user has entries.
WrappedData sampleWrapped(int year) => WrappedData(
      year: year,
      total: 12500,
      count: 23,
      topCategory: 'পূজা / ঈদ',
      topAmount: 5200,
      peakMonth: 10,
      peakAmount: 4100,
      owedToMe: 3000,
      iOwe: 800,
      loanCount: 3,
    );
