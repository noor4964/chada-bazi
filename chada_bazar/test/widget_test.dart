import 'package:flutter_test/flutter_test.dart';

import 'package:chada_bazar/util.dart';

void main() {
  test('Bangla digits and grouping', () {
    expect(bnInt(1234567), '১২,৩৪,৫৬৭');
    expect(bnInt(500), '৫০০');
    expect(firstNumber('১০০ টাকা দিই?'), 100);
    expect(firstNumber('দেব না'), isNull);
  });

  test('name filter blocks titles and long names', () {
    expect(cleanName('মন্ত্রী').$1, isNull);
    expect(cleanName('Awami').$1, isNull);
    expect(cleanName('এক দুই তিন').$1, isNull);
    expect(cleanName('  সাকিব ').$1, 'সাকিব');
    expect(cleanName('').$2, isNotNull);
  });
}
