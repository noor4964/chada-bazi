import 'package:flutter_test/flutter_test.dart';

import 'package:chada_bazar/baj_state.dart';
import 'package:chada_bazar/daily.dart';
import 'package:chada_bazar/duel.dart';
import 'package:chada_bazar/ledger.dart';
import 'package:chada_bazar/season.dart';
import 'package:chada_bazar/voice_script.dart';
import 'package:chada_bazar/wrapped.dart';

void main() {
  group('SeededRandom', () {
    test('same seed gives the same numbers, different seeds differ', () {
      final a = SeededRandom(42), b = SeededRandom(42), c = SeededRandom(43);
      final xs = [for (var i = 0; i < 20; i++) a.nextInt(1000)];
      final ys = [for (var i = 0; i < 20; i++) b.nextInt(1000)];
      final zs = [for (var i = 0; i < 20; i++) c.nextInt(1000)];
      expect(xs, ys);
      expect(xs, isNot(zs));
    });

    test('stays in range', () {
      final r = SeededRandom(7);
      for (var i = 0; i < 5000; i++) {
        final d = r.nextDouble();
        expect(d, inInclusiveRange(0, 1));
        expect(r.nextInt(6), inInclusiveRange(0, 5));
      }
    });
  });

  group('daily run', () {
    test('day numbers count from 1 Jan 2026', () {
      expect(dayNumber(DateTime(2026, 1, 1)), 1);
      expect(dayNumber(DateTime(2026, 1, 31)), 31);
      expect(dayNumber(DateTime(2027, 1, 1)), 366);
    });

    test('everyone gets the same lineup and outcomes on the same day', () {
      final a = DailyRun(100), b = DailyRun(100);
      expect(a.lineup.map((t) => t.id), b.lineup.map((t) => t.id));
      expect(a.lineup.length, 4);
      for (var i = 0; i < 5 && !a.finished; i++) {
        a.play(i % 4);
        b.play(i % 4);
      }
      expect(a.attempts.map((x) => x.emoji).join(), b.attempts.map((x) => x.emoji).join());
      expect(a.score, b.score);
      expect(a.shareText(), b.shareText());
    });

    test('a run ends after five tries or when caught, and cannot be replayed', () {
      final r = DailyRun(55);
      while (!r.finished) {
        r.play(0);
      }
      expect(r.attempts.length, lessThanOrEqualTo(dailyAttempts));
      expect(() => r.play(0), throwsStateError);
      if (r.caught) {
        expect(r.attempts.last.emoji, '🚔');
        expect(r.score, r.net ~/ 2);
      } else {
        expect(r.score, r.net);
      }
    });

    test('share text has day number, emoji row and score', () {
      final r = DailyRun(38)..play(0);
      final s = r.shareText();
      expect(s, startsWith('চাঁদা বাজার #৩৮ '));
      expect(s, contains('নেতা নিল'));
    });

    test('different days give different lineups at least sometimes', () {
      final lineups = {for (var d = 1; d <= 30; d++) DailyRun(d).lineup.map((t) => t.id).join(',')};
      expect(lineups.length, greaterThan(5));
    });
  });

  group('duel', () {
    DuelGame game() => DuelGame(bhai: 'রফিক', payer: 'নিলয়', startDemand: 500);

    test('accepting the first offer ends the game at that price', () {
      final g = game()..payerOffer(200);
      expect(g.status, DuelStatus.bhaiTurn);
      g.bhaiAccept();
      expect(g.finished, isTrue);
      expect(g.finalAmount, 200);
      expect(g.winner, 'payer'); // 200/500 = 40%
    });

    test('an offer at or above the demand is an instant deal', () {
      final g = game()..payerOffer(600);
      expect(g.status, DuelStatus.dealt);
      expect(g.finalAmount, 500);
      expect(g.winner, 'bhai');
    });

    test('counters must sit between the offer and the demand', () {
      final g = game()..payerOffer(100);
      expect(() => g.bhaiCounter(100), throwsArgumentError);
      expect(() => g.bhaiCounter(500), throwsArgumentError);
      g.bhaiCounter(400);
      expect(g.demand, 400);
      expect(g.round, 2);
      expect(g.status, DuelStatus.payerTurn);
    });

    test('no counter in the last round, only accept or get angry', () {
      final g = game();
      g.payerOffer(100);
      g.bhaiCounter(450);
      g.payerOffer(150);
      g.bhaiCounter(400);
      g.payerOffer(200);
      expect(g.round, duelMaxRounds);
      expect(g.canCounter, isFalse);
      expect(() => g.bhaiCounter(300), throwsStateError);
      g.bhaiAngry();
      expect(g.status, DuelStatus.angry);
      expect(g.finalAmount, 480); // 400 + 20%
      expect(g.winner, 'bhai');
    });

    test('a middle result is a draw', () {
      final g = game()..payerOffer(350);
      g.bhaiAccept();
      expect(g.winner, 'draw'); // 70%
    });

    test('turns are enforced', () {
      final g = game();
      expect(() => g.bhaiAccept(), throwsStateError);
      g.payerOffer(100);
      expect(() => g.payerOffer(200), throwsStateError);
    });
  });

  group('seasons and bulletin', () {
    test('a date inside a window finds the season, outside finds none', () {
      expect(currentSeason(DateTime(2026, 4, 14))?.name, 'পহেলা বৈশাখ');
      expect(currentSeason(DateTime(2026, 10, 15))?.name, 'পূজার মৌসুম');
      expect(currentSeason(DateTime(2026, 8, 15)), isNull);
    });

    test('window edges are inclusive', () {
      expect(currentSeason(DateTime(2026, 6, 1))?.id, 'budget2026');
      expect(currentSeason(DateTime(2026, 6, 12, 23, 59))?.id, 'budget2026');
      expect(currentSeason(DateTime(2026, 6, 13)), isNull);
    });

    test('next season is the nearest one that has not started', () {
      expect(nextSeason(DateTime(2026, 8, 15))?.id, 'puja2026');
    });

    test('season ids are unique and windows are valid', () {
      expect(seasons.map((s) => s.id).toSet().length, seasons.length);
      for (final s in seasons) {
        expect(s.end.isAfter(s.start), isTrue, reason: s.id);
        expect(s.multiplier, greaterThan(1));
      }
    });

    test('the same week always gives the same bulletin', () {
      final a = bulletinFor(DateTime(2026, 10, 12)), b = bulletinFor(DateTime(2026, 10, 18));
      expect(a.week, b.week);
      expect(a.items.map((i) => i.percent), b.items.map((i) => i.percent));
      expect(a.items.length, 5);
      expect(a.items.map((i) => i.name).toSet().length, 5);
      final next = bulletinFor(DateTime(2026, 10, 19));
      expect(next.week, a.week + 1);
    });
  });

  group('wrapped', () {
    Ledger sample() {
      final l = Ledger();
      l.addContribution(amount: 1000, category: 'ক্লাব', to: '', date: DateTime(2026, 3, 3));
      l.addContribution(amount: 3000, category: 'পূজা / ঈদ', to: '', date: DateTime(2026, 10, 5));
      l.addContribution(amount: 1000, category: 'পূজা / ঈদ', to: '', date: DateTime(2026, 10, 9));
      l.addContribution(amount: 500, category: 'চা-পানি', to: '', date: DateTime(2025, 12, 1));
      l.addLoan(person: 'সাকিব', amount: 2000, lent: true);
      return l;
    }

    test('picks the top category and the busiest month', () {
      final w = buildWrapped(sample(), 2026)!;
      expect(w.total, 5000);
      expect(w.count, 3);
      expect(w.topCategory, 'পূজা / ঈদ');
      expect(w.topAmount, 4000);
      expect(w.topPercent, 80);
      expect(w.peakMonth, 10);
      expect(w.peakAmount, 4000);
      expect(w.owedToMe, 2000);
      expect(w.title, 'নিয়মিত দাতা');
    });

    test('returns null when the year has no entries', () {
      expect(buildWrapped(sample(), 2024), isNull);
      expect(buildWrapped(Ledger(), 2026), isNull);
    });

    test('titles follow the total', () {
      WrappedData withTotal(int t) => WrappedData(
            year: 2026, total: t, count: 1, topCategory: 'x', topAmount: t, peakMonth: 1,
            peakAmount: t, owedToMe: 0, iOwe: 0, loanCount: 0,
          );
      expect(withTotal(500).title, 'নতুন ভিকটিম');
      expect(withTotal(9000).title, 'দানবীর হাতেম তাই');
      expect(withTotal(30000).title, 'পাড়ার ATM');
    });
  });

  test('voice scripts put the nickname in and never leave a placeholder', () {
    for (var i = 0; i < voiceSituations.length; i++) {
      final s = buildVoiceScript('সাকিব', i);
      expect(s, contains('সাকিব'));
      expect(s, isNot(contains('{n}')));
    }
    expect(buildVoiceScript('রাফি', 99), contains('রাফি')); // out-of-range clamps
    expect(voiceProfiles.every((p) => p.pitch > 0 && p.rate > 0), isTrue);
  });

  test('season multiplier scales collector amounts', () {
    final t = targets.firstWhere((x) => x.id == 'mama');
    int maxGross(double mult) {
      var m = 0;
      for (var i = 0; i < 400; i++) {
        final r = rollOutcome(t, SeededRandom(i), amountMult: mult);
        if (r.gross > m) m = r.gross;
      }
      return m;
    }

    expect(maxGross(1.5), greaterThan(maxGross(1.0)));
  });
}
