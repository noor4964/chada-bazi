import 'daily.dart';
import 'util.dart';

/// A festival or event window that changes the game for a few days.
/// Dates of moving festivals are approximate and need a yearly update.
class Season {
  final String id, name, emoji, tagline;
  final DateTime start, end;

  /// Scales chada amounts in the collector game.
  final double multiplier;
  final List<String> tickerLines;
  const Season({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.start,
    required this.end,
    required this.multiplier,
    required this.tickerLines,
  });

  bool contains(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

final seasons = <Season>[
  for (final y in [2026, 2027]) ...[
    Season(
      id: 'boishakh$y', name: 'পহেলা বৈশাখ', emoji: '🎊', tagline: 'নতুন বছর, নতুন খাতা, পুরোনো চাঁদা',
      start: DateTime(y, 4, 10), end: DateTime(y, 4, 17), multiplier: 1.5,
      tickerLines: const ['বৈশাখী মেলার চাঁদা এবার ডাবল', 'হালখাতার মিষ্টির টাকা ভাইয়ের পকেটে'],
    ),
    Season(
      id: 'budget$y', name: 'বাজেট সপ্তাহ', emoji: '📊', tagline: 'সব কিছুর দাম বাড়ে, চাঁদাও',
      start: DateTime(y, 6, 1), end: DateTime(y, 6, 12), multiplier: 1.3,
      tickerLines: const ['বাজেট ঘোষণার পর ভাইয়ের "বাজেট চাঁদা" চালু', 'চা-সিঙ্গারার দাম বেড়েছে, চাঁদাও বেড়েছে'],
    ),
  ],
  Season(
    id: 'eid-fitr2026', name: 'ঈদের মৌসুম', emoji: '🌙', tagline: 'ঈদের আগে ভাইদর আকাশছোঁয়া',
    start: DateTime(2026, 3, 14), end: DateTime(2026, 3, 24), multiplier: 1.5,
    tickerLines: const ['ঈদের আগে ভাইয়ের ফোন বন্ধ থাকে না', 'ঈদ বোনাসের গন্ধ পেয়েছে ভাই'],
  ),
  Season(
    id: 'eid-adha2026', name: 'কোরবানির মৌসুম', emoji: '🐐', tagline: 'হাট বসেছে, চাঁদাও বসেছে',
    start: DateTime(2026, 5, 22), end: DateTime(2026, 5, 31), multiplier: 1.5,
    tickerLines: const ['হাটের ইজারা আর চাঁদার ইজারা এক নয়, ভাইরা জানে না'],
  ),
  Season(
    id: 'puja2026', name: 'পূজার মৌসুম', emoji: '🪔', tagline: 'প্যান্ডেলের আলোয় চাঁদার হিসাব',
    start: DateTime(2026, 10, 13), end: DateTime(2026, 10, 22), multiplier: 1.5,
    tickerLines: const ['মণ্ডপ সাজাতে লাইটের চাঁদা, লাইটে লাগে ভাইয়ের ভাতিজা', 'ঢাকের তালে চাঁদার তাল'],
  ),
  Season(
    id: 'eid-fitr2027', name: 'ঈদের মৌসুম', emoji: '🌙', tagline: 'ঈদের আগে ভাইদর আকাশছোঁয়া',
    start: DateTime(2027, 3, 3), end: DateTime(2027, 3, 13), multiplier: 1.5,
    tickerLines: const ['ঈদের আগে ভাইয়ের ফোন বন্ধ থাকে না'],
  ),
  Season(
    id: 'eid-adha2027', name: 'কোরবানির মৌসুম', emoji: '🐐', tagline: 'হাট বসেছে, চাঁদাও বসেছে',
    start: DateTime(2027, 5, 10), end: DateTime(2027, 5, 19), multiplier: 1.5,
    tickerLines: const ['হাটের ইজারা আর চাঁদার ইজারা এক নয়, ভাইরা জানে না'],
  ),
  Season(
    id: 'puja2027', name: 'পূজার মৌসুম', emoji: '🪔', tagline: 'প্যান্ডেলের আলোয় চাঁদার হিসাব',
    start: DateTime(2027, 10, 3), end: DateTime(2027, 10, 12), multiplier: 1.5,
    tickerLines: const ['ঢাকের তালে চাঁদার তাল'],
  ),
];

/// The season running on [now], or null.
Season? currentSeason(DateTime now) {
  for (final s in seasons) {
    if (s.contains(now)) return s;
  }
  return null;
}

/// The next season that has not started yet, or null.
Season? nextSeason(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  Season? best;
  for (final s in seasons) {
    if (s.start.isAfter(day) && (best == null || s.start.isBefore(best.start))) best = s;
  }
  return best;
}

// ---------------------------------------------------------- weekly news ---

class BulletinItem {
  final String name;
  final int percent;
  final String note;
  const BulletinItem(this.name, this.percent, this.note);
}

class Bulletin {
  final int week;
  final List<BulletinItem> items;
  final String headline;
  const Bulletin(this.week, this.items, this.headline);

  /// Average change across the items.
  int get index => (items.fold<int>(0, (s, i) => s + i.percent) / items.length).round();
}

const _goods = <(String, List<String>)>[
  ('চা-সিঙ্গারা ফান্ড', ['চায়ের পাতার দাম বাড়ায়', 'সিঙ্গারা ছোট হয়েছে, ফান্ড বড় হয়েছে', 'ভাইয়ের তিন কাপ চা লাগে']),
  ('মাইক ভাড়া', ['মাইক বাজেনি, ভাড়া ঠিকই বেড়েছে', 'ভাড়ার মাইক নাকি সোনার', 'ব্যাটারির দাম বেড়েছে বলে']),
  ('রসিদ ছাপানো', ['কাগজের দাম বেড়েছে, রসিদ বই এখন বিলাসী', 'ছাপাখানা বলল ভাইয়ের জন্য স্পেশাল রেট']),
  ('ভাইয়ের বাইকের তেল', ['তেলের দাম বাড়লে বাইক বেশি ঘুরে', 'পেট্রোলের দাম বাড়ায় ভাই আরও রাগী']),
  ('ভাতিজার সার্ভিস', ['ভাতিজা এখন বেশি কাজ করে', 'ভাতিজা ইউনিয়ন করেছে', 'সার্ভিসের সার্ভিস চার্জ যোগ']),
  ('নেতার ভাগ', ['নেতা বলেছেন ১০% আর কমবে না', 'ভাগ ঠিকই আছে, নেতার হাসি বেড়েছে']),
];

/// A made-up price report. The same week always gives the same report.
Bulletin bulletinFor(DateTime date) {
  // Day 1 (1 Jan 2026) is a Thursday, so +2 makes each week run Monday to Sunday.
  final week = (dayNumber(date) + 2) ~/ 7;
  final rng = SeededRandom(week * 977 + 13);
  final picked = (List.of(_goods)..shuffle(rng)).take(5).toList();
  final items = [
    for (final g in picked) BulletinItem(g.$1, rng.nextInt(41) - 5, g.$2[rng.nextInt(g.$2.length)]),
  ];
  final idx = (items.fold<int>(0, (s, i) => s + i.percent) / items.length).round();
  final headline = idx >= 15
      ? 'চাঁদা মুদ্রাস্ফীতি আকাশে, ভাইয়ের মুখে হাসি'
      : idx >= 5
          ? 'চাঁদা মুদ্রাস্ফীতি চড়া, তবে ভাই আশাবাদী'
          : 'চাঁদার বাজার কিছুটা শান্ত, ভাই সুযোগ খুঁজছে';
  return Bulletin(week, items, headline);
}

String signedPercent(int p) => '${p >= 0 ? '+' : '-'}${bnInt(p.abs())}%';
