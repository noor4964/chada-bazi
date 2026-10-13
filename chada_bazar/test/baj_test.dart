import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:chada_bazar/baj_state.dart';

void main() {
  test('many collections never break the invariants', () {
    final s = BajState();
    final rng = Random(7);
    for (var i = 0; i < 3000; i++) {
      final t = targets[rng.nextInt(targets.length)];
      final r = s.collect(t, rng);
      expect(s.cash, greaterThanOrEqualTo(0));
      expect(s.heat, inInclusiveRange(0, 100));
      expect(r.net, r.gross - r.tax);
      expect(r.tax, (r.gross * leaderTaxPercent / 100).round());
      if (r.caught) {
        expect(s.heat, 30);
        expect(r.fine, greaterThanOrEqualTo(0));
      }
      if (i % 40 == 0) s.cash += 500; // keep money flowing
    }
    expect(s.taxPaid, greaterThan(0));
    expect(s.collected, greaterThan(s.taxPaid));
    expect(s.caught, greaterThan(0)); // risky targets eventually get you caught
  });

  test('upgrades cost more each level, stop at max, and need cash', () {
    final s = BajState();
    final mic = upgradeDefs.firstWhere((d) => d.id == UpgradeId.mic);
    expect(upgradeCost(mic, 1), greaterThan(upgradeCost(mic, 0)));

    s.cash = 0;
    expect(s.buy(mic), isFalse);

    s.cash = 100000;
    for (var i = 0; i < mic.maxLevel; i++) {
      expect(s.buy(mic), isTrue);
    }
    expect(s.level(UpgradeId.mic), mic.maxLevel);
    expect(s.buy(mic), isFalse);
  });

  test('cooling down costs money and lowers heat', () {
    final s = BajState()
      ..cash = 500
      ..heat = 60;
    expect(s.coolDown(), isTrue);
    expect(s.cash, 400);
    expect(s.heat, 35);

    s.cash = 50;
    expect(s.coolDown(), isFalse);
    expect(s.cash, 50);
  });

  test('ranks follow total collected', () {
    final s = BajState();
    expect(s.rankName, 'পাড়ার নতুন ভাই');
    s.collected = 12000;
    expect(s.rankName, 'এলাকার ভাই');
    s.collected = 1000000;
    expect(s.rankName, 'বড় ভাই');
  });

  test('every target has outcome lines and valid odds', () {
    for (final t in targets) {
      expect(t.payLines, isNotEmpty);
      expect(t.haggleLines, isNotEmpty);
      expect(t.fleeLines, isNotEmpty);
      expect(t.pay + t.haggle + t.flee, lessThanOrEqualTo(1.0), reason: t.id);
      expect(t.minAmt, lessThan(t.maxAmt));
    }
  });
}
