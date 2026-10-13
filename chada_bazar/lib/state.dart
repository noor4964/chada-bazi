import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'util.dart';

const badgeDefs = <String, (String, String)>{
  'rosid': ('🧾', 'প্রথম রসিদ'),
  'notice': ('📮', 'বন্ধুকে ফাঁসিয়েছ'),
  'quiz': ('🧠', 'নিজেকে চিনেছ'),
  'call5': ('📵', '৫ কল কেটেছ'),
  'answered': ('📞', 'ভাইয়ের কল ধরেছ'),
  'haggle': ('📈', 'দরকষাকষিতে হেরেছ'),
  'escape': ('🏃', 'পালানো শিল্পী'),
  'file': ('🗂️', 'ফাইল জমা দিয়েছ'),
  'streak3': ('🔥', '৩ দিনের স্ট্রিক'),
  'k5': ('💸', '৳৫,০০০ ক্লাব'),
  'khata1': ('📒', 'প্রথম খাতা'),
  'bajfirst': ('🏍️', 'প্রথম চাঁদা তুললে'),
  'caught1': ('🚔', 'প্রথমবার ধরা'),
  'upgrade1': ('🎤', 'প্রথম আপগ্রেড'),
  'daily1': ('📅', 'প্রথম দৈনিক রান'),
  'idcard1': ('🪪', 'পরিচয়পত্র পেয়েছ'),
  'voice1': ('📢', 'ভাইয়ের ভয়েস বাজিয়েছ'),
  'duel1': ('🤝', 'ফোন পাস দরকষাকষি'),
  'wrapped1': ('🎞️', 'Wrapped দেখেছ'),
};

const levels = <(int, String)>[
  (0, 'নবিশ'),
  (500, 'নিয়মিত দাতা'),
  (2000, 'পাড়ার ATM'),
  (6000, 'ভাইয়ের প্রিয়'),
  (15000, 'চাঁদা কিংবদন্তি'),
];
const moods = ['😐', '🙂', '😏', '😎', '🤑'];

class AppState extends ChangeNotifier {
  int paid = 0, escapes = 0, missed = 0, taken = 0, fine = 0, outages = 0, streak = 1;
  String last = '';

  /// 'data' (payer) or 'baj' (collector). Null until the user picks on first launch.
  String? perspective;
  Map<String, int> quiz = {};
  final Set<String> badges = {};
  SharedPreferences? _p;

  /// Set by the app shell so any screen can show a toast and a badge pop-up.
  void Function(String)? onToast;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      final j = jsonDecode(_p!.getString('chada2') ?? '{}') as Map<String, dynamic>;
      paid = j['paid'] ?? 0;
      escapes = j['escapes'] ?? 0;
      missed = j['missed'] ?? 0;
      taken = j['taken'] ?? 0;
      fine = j['fine'] ?? 0;
      outages = j['outages'] ?? 0;
      streak = j['streak'] ?? 1;
      last = j['last'] ?? '';
      perspective = j['perspective'] as String?;
      badges
        ..clear()
        ..addAll(List<String>.from(j['badges'] ?? const []));
      quiz = Map<String, int>.from(j['quiz'] ?? const {});
    } catch (_) {}
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final y = now.subtract(const Duration(days: 1));
    final yesterday = '${y.year}-${y.month}-${y.day}';
    if (last != today) {
      streak = last == yesterday ? streak + 1 : 1;
      last = today;
    }
    _save();
    notifyListeners();
    if (streak >= 3) Future.delayed(const Duration(milliseconds: 1500), () => badge('streak3'));
  }

  void _save() {
    _p?.setString(
      'chada2',
      jsonEncode({
        'paid': paid, 'escapes': escapes, 'missed': missed, 'taken': taken, 'fine': fine,
        'outages': outages, 'streak': streak, 'last': last, 'perspective': perspective,
        'badges': badges.toList(), 'quiz': quiz,
      }),
    );
  }

  void update(void Function() f) {
    f();
    _save();
    notifyListeners();
  }

  void setPerspective(String p) => update(() => perspective = p);

  void pay(int n) {
    update(() => paid += n);
    if (paid >= 5000) badge('k5');
  }

  void badge(String id) {
    if (badges.contains(id)) return;
    badges.add(id);
    _save();
    notifyListeners();
    final b = badgeDefs[id]!;
    onToast?.call('নতুন ব্যাজ: ${b.$1} ${b.$2}');
  }

  void reset() {
    paid = escapes = missed = taken = fine = outages = 0;
    streak = 1;
    quiz = {};
    badges.clear();
    final now = DateTime.now();
    last = '${now.year}-${now.month}-${now.day}';
    _save();
    notifyListeners();
  }

  int get levelIndex {
    var li = 0;
    for (var i = 0; i < levels.length; i++) {
      if (paid >= levels[i].$1) li = i;
    }
    return li;
  }

  String get levelName => levels[levelIndex].$2;
  String get mood => moods[levelIndex];
}

final app = AppState();
final rng = Random();

T pick<T>(List<T> a) => a[rng.nextInt(a.length)];
int rnd(int a, int b) => a + rng.nextInt(b - a + 1);
List<T> shuffled<T>(List<T> a) => List<T>.of(a)..shuffle(rng);

String tk(num n) => '৳${bnInt(n.round())}';
