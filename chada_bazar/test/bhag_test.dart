import 'package:flutter_test/flutter_test.dart';

import 'package:chada_bazar/screens/bhag.dart';

void main() {
  test('10% leader cut on 10,000 leaves 82% for the work', () {
    final r = splitCuts(10000, 10);
    expect(r.cuts.first.name, 'নেতার ভাগ');
    expect(r.cuts.first.amount, 1000);
    expect(r.remaining, 8200); // 10 + 2 + 3 + 1 + 2 = 18% taken
  });

  test('parts always add up to the total, even with rounding', () {
    for (final total in [1, 7, 99, 1234, 5555, 100001]) {
      for (final pct in [0, 10, 17, 30]) {
        final r = splitCuts(total, pct);
        final sum = r.cuts.fold<int>(0, (s, c) => s + c.amount) + r.remaining;
        expect(sum, total, reason: 'total=$total pct=$pct');
        expect(r.remaining, greaterThanOrEqualTo(0));
      }
    }
  });

  test('zero collected gives zero everywhere', () {
    final r = splitCuts(0, 10);
    expect(r.remaining, 0);
    expect(r.cuts.every((c) => c.amount == 0), isTrue);
  });
}
