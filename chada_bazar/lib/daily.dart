import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'baj_state.dart';
import 'state.dart' show tk;
import 'util.dart';

/// Park-Miller generator. It uses only multiplication and modulo on values
/// below 2^47, so it gives exactly the same numbers on web and on phones.
/// The daily run needs that so every player gets the same luck.
class SeededRandom implements Random {
  int _x;
  SeededRandom(int seed) : _x = (seed.abs() % 2147483646) + 1 {
    for (var i = 0; i < 3; i++) {
      nextDouble();
    }
  }

  @override
  double nextDouble() {
    _x = (_x * 48271) % 2147483647;
    return _x / 2147483647;
  }

  @override
  int nextInt(int max) => (nextDouble() * max).floor();

  @override
  bool nextBool() => nextDouble() < 0.5;
}

/// Day 1 is 1 January 2026.
int dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2026, 1, 1)).inDays + 1;

const dailyAttempts = 5;

class DailyAttempt {
  final Target target;
  final Roll roll;
  final int tax, net;
  final bool caught;
  const DailyAttempt(this.target, this.roll, this.tax, this.net, this.caught);

  String get emoji {
    if (caught) return '🚔';
    return switch (roll.kind) {
      Kind.paid => '💰',
      Kind.haggled => '🤝',
      Kind.fled => '🙈',
      Kind.complained => '😤',
    };
  }
}

/// One day's run: the same four neighbours and the same dice for everyone.
class DailyRun {
  final int day;
  final List<Target> lineup;
  final List<int> picks = [];
  final List<DailyAttempt> attempts = [];
  int heat = 0;

  DailyRun(this.day) : lineup = (List<Target>.of(targets)..shuffle(SeededRandom(day * 31 + 7))).take(4).toList();

  bool get caught => attempts.isNotEmpty && attempts.last.caught;
  bool get finished => attempts.length >= dailyAttempts || caught;
  int get net => attempts.fold(0, (s, a) => s + a.net);
  int get tax => attempts.fold(0, (s, a) => s + a.tax);

  /// Being caught costs half of what you made.
  int get score => caught ? net ~/ 2 : net;

  DailyAttempt play(int lineupIndex) {
    if (finished) throw StateError('run already finished');
    final t = lineup[lineupIndex];
    final rng = SeededRandom(day * 7919 + attempts.length * 131 + targets.indexOf(t) * 17 + 1);
    final roll = rollOutcome(t, rng);
    heat = (heat + roll.heatDelta).clamp(0, 100);
    final tax = (roll.gross * leaderTaxPercent / 100).round();
    final a = DailyAttempt(t, roll, tax, roll.gross - tax, heat >= 100);
    picks.add(lineupIndex);
    attempts.add(a);
    return a;
  }

  /// Plain text, so it pastes into any chat without an image.
  String shareText() => 'চাঁদা বাজার #${bnInt(day)} ${attempts.map((a) => a.emoji).join()} ${tk(score)} · নেতা নিল ${tk(tax)}';
}

/// Today's run, plus streak and best score, saved on the device.
class DailyStore extends ChangeNotifier {
  static const _key = 'daily1';
  late DailyRun run = DailyRun(dayNumber(DateTime.now()));
  int streak = 0, lastDay = 0, best = 0;
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      final j = jsonDecode(_p!.getString(_key) ?? '{}') as Map<String, dynamic>;
      streak = j['streak'] ?? 0;
      lastDay = j['last'] ?? 0;
      best = j['best'] ?? 0;
      final today = dayNumber(DateTime.now());
      run = DailyRun(today);
      if (j['day'] == today) {
        for (final i in List<int>.from(j['picks'] ?? const [])) {
          if (!run.finished) run.play(i);
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Starts a fresh run if the date changed while the app was open.
  void ensureToday() {
    final today = dayNumber(DateTime.now());
    if (run.day != today) {
      run = DailyRun(today);
      notifyListeners();
    }
  }

  DailyAttempt play(int i) {
    ensureToday();
    final a = run.play(i);
    if (run.finished && lastDay != run.day) {
      streak = lastDay == run.day - 1 ? streak + 1 : 1;
      lastDay = run.day;
      best = max(best, run.score);
    }
    _p?.setString(_key, jsonEncode({'day': run.day, 'picks': run.picks, 'streak': streak, 'last': lastDay, 'best': best}));
    notifyListeners();
    return a;
  }

  /// True while today's run is still in progress or not started.
  bool get canPlay => !run.finished;
}

final daily = DailyStore();
