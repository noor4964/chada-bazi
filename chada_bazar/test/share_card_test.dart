import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chada_bazar/share_card.dart';

/// Every kicker the app passes to a share card.
const _kickers = [
  'রসিদ নং ১২৩৪', 'ভিকটিম কুইজ', 'মিসড কল রিপোর্ট', 'দরকষাকষির ফলাফল', 'পালাও চ্যালেঞ্জ', 'নেতার ভাগ',
  'আজকের চাঁদা #২৮৬', 'ভাইগিরি রিপোর্ট', 'সপ্তাহ ৪১', 'স্মারক চাঁ/১২৩/২০২৬', 'ধার ফেরত নোটিশ', 'ভাইয়ের ভয়েস',
  'পাড়ার মাইক', 'ফোন পাস দরকষাকষি', 'ফাইল ট্র্যাকার', 'বার্ষিক চাঁদা রিপোর্ট',
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('every kicker the app uses gets its own POV caption ending in an emoji', () {
    for (final k in _kickers) {
      final pov = povFor(ShareCardData(kicker: k, title: 't'));
      expect(pov, startsWith('POV: '), reason: k);
      expect(pov, isNot(povFor(const ShareCardData(kicker: 'zzz', title: 't'))), reason: '$k fell through to the default');
    }
  });

  test('duel card is not mistaken for the generic haggling card', () {
    expect(povFor(const ShareCardData(kicker: 'ফোন পাস দরকষাকষি', title: 't')), contains('দুজনে'));
    expect(povFor(const ShareCardData(kicker: 'দরকষাকষির ফলাফল', title: 't')), contains('লস'));
  });

  test('stickers are four emoji and vary between cards', () {
    final a = stickersFor(const ShareCardData(kicker: 'নেতার ভাগ', title: 'x'));
    final b = stickersFor(const ShareCardData(kicker: 'পালাও চ্যালেঞ্জ', title: 'a much longer title'));
    expect(a.length, 4);
    expect(b.length, 4);
    expect(a, isNot(b));
  });

  // The worst case the app produces: long title, many rows, long punchline and a stamp.
  const worst = ShareCardData(
    kicker: 'ফোন পাস দরকষাকষি',
    title: 'রফিক ভাই ৳১,০০০ চেয়েছিল আর নিলয় শেষ পর্যন্ত দিল মাত্র ৳১০০ বলে জিতে গেল',
    rows: [
      ('রফিক: চাঁদা ৳১,০০০। দর কষা চলবে, তবে আমার দিকে।', null),
      ('নিলয়: ৳১০০ দিই?', null),
      ('রফিক: না, ৳৯০০ দাও।', null),
      ('নিলয়: ৳২০০ দিই?', null),
      ('রফিক: না, ৳৮০০ দাও।', null),
      ('সর্বমোট বেশ লম্বা একটা লেবেল যেটা দুই লাইনে যাবে', '৳১,২৩,৪৫৬'),
      ('আরেকটা সারি', '৳৫০০'),
    ],
    big: 'শেষ দাম ৳১০০। ভাইয়ের হাত থেকে কেউ বাঁচে না, তবে আজ নিলয় বেঁচে গেল, এটাই আজকের সেরা খবর।',
    stamp: 'দরকষাকষি চ্যাম্পিয়ন',
  );
  const bare = ShareCardData(kicker: 'নেতার ভাগ', title: 'ছোট শিরোনাম');

  for (final style in CardStyle.values) {
    for (final story in [false, true]) {
      for (final entry in {'worst case': worst, 'no rows': bare}.entries) {
        testWidgets('${style.name} ${story ? 'story' : 'post'} with ${entry.key} lays out without overflow', (tester) async {
          tester.view.physicalSize = const Size(1200, 2000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(body: Center(child: RepaintBoundary(child: ShareCardView(data: entry.value, style: style, story: story)))),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final size = tester.getSize(find.byType(ShareCardView));
          expect(size.width, 360);
          expect(size.height, story ? 640 : 450);
        });
      }
    }
  }
}
