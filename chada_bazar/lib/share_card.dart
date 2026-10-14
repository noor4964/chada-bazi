import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// What a share card shows. [kicker] is the small label, [rows] are the
/// label and value lines, [big] is the punchline, [stamp] a rubber-stamp word.
class ShareCardData {
  final String kicker, title;
  final List<(String, String?)> rows;
  final String? big, stamp;
  const ShareCardData({
    required this.kicker,
    required this.title,
    this.rows = const [],
    this.big,
    this.stamp,
  });
}

enum CardStyle { sticker, neon, y2k }

extension CardStyleLabel on CardStyle {
  String get label => switch (this) {
        CardStyle.sticker => 'স্টিকার',
        CardStyle.neon => 'নিয়ন',
        CardStyle.y2k => 'Y2K',
      };
}

/// A short "POV:" caption picked from the card's kicker. The last word is an emoji.
String povFor(ShareCardData d) {
  final k = d.kicker;
  const table = <String, String>{
    'রসিদ': 'POV: ভাই তোমাকে রসিদ ধরিয়ে দিল 🧾',
    'কুইজ': 'POV: কুইজ বলছে তুমিই সেই ভিকটিম 😭',
    'মিসড কল': 'POV: ভাই আবার ফোন দিয়েছে 📵',
    // More specific keys come first: the duel kicker also contains "দরকষাকষি".
    'ফোন পাস': 'POV: দুজনে একটাই ফোন 🤝',
    'দরকষাকষি': 'POV: দরদাম করতে গিয়ে আরও লস 📉',
    'পালাও': 'POV: বাটন তোমার চেয়ে ফাস্ট 🏃',
    'নেতার ভাগ': 'POV: নেতার ১০% আগেই কাটা 💸',
    'আজকের চাঁদা': 'POV: আজকের পাড়া, আজকের ভাগ্য 🎲',
    'ভাইগিরি': 'POV: এখন তুমিই পাড়ার ভাই 😎',
    'সপ্তাহ': 'POV: এ সপ্তাহে ভাইদর আবার আকাশে 📈',
    'স্মারক': 'POV: বন্ধুর নামে নোটিশ জারি 🚨',
    'নোটিশ': 'POV: বন্ধুর নামে নোটিশ জারি 🚨',
    'ভয়েস': 'POV: ভাইয়ের গলা শুনে ফেললে 📢',
    'মাইক': 'POV: মাইকে নাম শুনে ফেললে 📢',
    'ফাইল': 'POV: তোমার ফাইল ঘুমাচ্ছে 🗂️',
    'বার্ষিক': 'POV: বছর শেষে হিসাব মেলাচ্ছি 📒',
  };
  for (final e in table.entries) {
    if (k.contains(e.key)) return e.value;
  }
  return 'POV: ভাই তোমাকে খুঁজছে 👀';
}

/// Four floating emoji stickers: the caption's emoji plus a few staples,
/// in an order that depends on the card so different cards look different.
List<String> stickersFor(ShareCardData d) {
  final last = povFor(d).split(' ').last;
  final pool = ['💸', '🔥', '😭', '🤡', '👀', '✨', '🚨', '💀'];
  final h = (d.kicker.length * 31 + d.title.length * 17) % pool.length;
  return [last, pool[h], pool[(h + 3) % pool.length], pool[(h + 5) % pool.length]];
}

const _ink = Color(0xFF1C1A16);
const _paper = Color(0xFFFFFBEF);
const _red = Color(0xFFC8102E);
const _yellow = Color(0xFFF7C600);

/// The image people share. Fixed 360 wide: 450 tall for a post (4:5) or 640
/// for a story (9:16). Rendered at 3x it becomes 1080x1350 or 1080x1920.
class ShareCardView extends StatelessWidget {
  final ShareCardData data;
  final CardStyle style;
  final bool story;
  const ShareCardView({super.key, required this.data, this.style = CardStyle.sticker, this.story = false});

  static const width = 360.0;
  double get height => story ? 640 : 450;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: switch (style) {
        CardStyle.sticker => _Sticker(data, story),
        CardStyle.neon => _Neon(data, story),
        CardStyle.y2k => _Y2k(data, story),
      },
    );
  }
}

// ------------------------------------------------------------- helpers ----

Widget _outlined(String text, double size, Color fill, Color stroke, {int maxLines = 3, double strokeWidth = 6}) {
  return Stack(children: [
    Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: body(size, w: FontWeight.w700, h: 1.15).copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = stroke,
      ),
    ),
    Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: body(size, w: FontWeight.w700, color: fill, h: 1.15)),
  ]);
}

/// A row list: label on the left, bold value on the right.
Widget _rows(ShareCardData d, {required Color label, required Color value, required Color line, double size = 13.5, double vpad = 5}) {
  return Column(mainAxisSize: MainAxisSize.min, children: [
    for (var i = 0; i < d.rows.length; i++)
      Container(
        padding: EdgeInsets.symmetric(vertical: vpad),
        decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(d.rows[i].$1, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(size, color: label, h: 1.3))),
          if (d.rows[i].$2 != null) ...[
            const SizedBox(width: 10),
            Text(d.rows[i].$2!, style: body(size + .5, w: FontWeight.w700, color: value, h: 1.3)),
          ],
        ]),
      ),
  ]);
}

/// A rotated rubber-stamp word that floats over the card.
Widget _stampSticker(String text, {required Color fill, required Color line, required Color ink, BorderRadius? radius}) => Transform.rotate(
      angle: -0.2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: fill, border: Border.all(color: line, width: 3), borderRadius: radius ?? BorderRadius.circular(8)),
        child: Text(text, maxLines: 1, style: body(18, w: FontWeight.w700, color: ink, h: 1.2)),
      ),
    );

Widget _sticker(String emoji, double size, double angle) =>
    Transform.rotate(angle: angle, child: Text(emoji, style: TextStyle(fontSize: size, height: 1)));

class _DotsPainter extends CustomPainter {
  final Color color;
  const _DotsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 18.0;
    for (var y = 0.0, row = 0; y < size.height + step; y += step, row++) {
      for (var x = (row.isEven ? 0.0 : step / 2); x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), 2.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter o) => o.color != color;
}

// ------------------------------------------------------------- sticker ----
// Neo-brutalist: thick outlines, hard shadows, tilted blocks on yellow dots.

class _Sticker extends StatelessWidget {
  final ShareCardData d;
  final bool story;
  const _Sticker(this.d, this.story);

  Widget _box(Color bg, Widget child, {double angle = 0, EdgeInsets pad = const EdgeInsets.fromLTRB(14, 10, 14, 10)}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: pad,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: _ink, width: 3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: _ink, offset: Offset(5, 5))],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = stickersFor(d);
    return Stack(children: [
      Positioned.fill(child: Container(color: _yellow, child: const CustomPaint(painter: _DotsPainter(Color(0x221C1A16))))),
      Positioned(right: 4, top: story ? 128 : 84, child: _sticker(st[0], 42, .25)),
      Positioned(left: 4, top: story ? 250 : 170, child: _sticker(st[1], 30, -.3)),
      if (story) Positioned(right: 8, bottom: 120, child: _sticker(st[2], 34, .2)),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 22, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('চাঁদা বাজার', maxLines: 1, style: display(26, color: _red)),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(99)),
                child: Text(d.kicker, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, w: FontWeight.w700, color: _yellow, h: 1.3)),
              ),
            ),
          ]),
          SizedBox(height: story ? 26 : 14),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 314,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _box(_paper, Text(povFor(d), style: body(14.5, w: FontWeight.w700, color: _ink, h: 1.3)), angle: -0.02),
                  SizedBox(height: story ? 20 : 10),
                  _box(_red, Text(d.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: body(story ? 30 : 22, w: FontWeight.w700, color: Colors.white, h: 1.2)), angle: 0.018, pad: const EdgeInsets.fromLTRB(14, 12, 14, 14)),
                  SizedBox(height: story ? 20 : 10),
                  if (d.rows.isNotEmpty) _box(_paper, _rows(d, label: _ink.withValues(alpha: .8), value: _ink, line: _ink.withValues(alpha: .18), size: story ? 13.5 : 12.5, vpad: story ? 5 : 3), pad: const EdgeInsets.fromLTRB(14, 6, 14, 6)),
                  if (d.big != null) ...[
                    SizedBox(height: story ? 14 : 10),
                    _box(_ink, Text(d.big!, style: body(story ? 16.5 : 15, w: FontWeight.w700, color: _yellow, h: 1.35)), angle: -0.012),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              Expanded(child: Text('তোমারটা বানাও →', style: body(14, w: FontWeight.w700, color: _yellow, h: 1.2))),
            ]),
          ),
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown, child: Text('github.com/noor4964/chada-bazi · ব্যঙ্গ ও বিনোদন। আসল চাঁদাবাজি অপরাধ।', maxLines: 1, style: body(9, color: _ink.withValues(alpha: .7), h: 1.2))),
        ]),
      ),
      if (d.stamp != null) Positioned(right: 18, bottom: 36, child: _stampSticker(d.stamp!, fill: _paper, line: _red, ink: _red)),
    ]);
  }
}

// ---------------------------------------------------------------- neon ----
// Dark with glowing blobs, gradient title and glassy panels.

class _Neon extends StatelessWidget {
  final ShareCardData d;
  final bool story;
  const _Neon(this.d, this.story);

  static const _pink = Color(0xFFFF2E93);
  static const _cyan = Color(0xFF00E5FF);
  static const _lime = Color(0xFFC6FF00);

  Widget _glow(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c.withValues(alpha: .55), c.withValues(alpha: 0)])),
      );

  @override
  Widget build(BuildContext context) {
    final st = stickersFor(d);
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0B0A12), Color(0xFF1B1035), Color(0xFF0B0A12)]),
          ),
        ),
      ),
      Positioned(left: -90, top: -70, child: _glow(_pink, 340)),
      Positioned(right: -110, bottom: story ? 120 : 60, child: _glow(_cyan, 340)),
      if (story) Positioned(left: -80, bottom: -60, child: _glow(_lime, 260)),
      Positioned(right: 4, top: story ? 120 : 80, child: _sticker(st[0], 42, .25)),
      Positioned(left: 6, top: story ? 300 : 200, child: _sticker(st[1], 28, -.3)),
      if (story) Positioned(right: 10, bottom: 130, child: _sticker(st[2], 32, .2)),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('চাঁদা বাজার', maxLines: 1, style: display(26, color: Colors.white).copyWith(shadows: [const Shadow(color: _pink, blurRadius: 14)])),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(border: Border.all(color: _cyan, width: 1.5), borderRadius: BorderRadius.circular(99)),
                child: Text(d.kicker, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, w: FontWeight.w700, color: _cyan, h: 1.3)),
              ),
            ),
          ]),
          SizedBox(height: story ? 28 : 16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 316,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(povFor(d), style: body(14.5, w: FontWeight.w600, color: _cyan, h: 1.35)),
                  SizedBox(height: story ? 14 : 8),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [_pink, Color(0xFFFFD23F), _cyan]).createShader(r),
                    child: Text(d.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: body(story ? 34 : 25, w: FontWeight.w700, color: Colors.white, h: 1.15)),
                  ),
                  SizedBox(height: story ? 20 : 10),
                  if (d.rows.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .07),
                        border: Border.all(color: _cyan.withValues(alpha: .55), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _rows(d, label: Colors.white.withValues(alpha: .85), value: _lime, line: Colors.white.withValues(alpha: .15), size: story ? 13.5 : 12.5, vpad: story ? 5 : 3),
                    ),
                  if (d.big != null) ...[
                    SizedBox(height: story ? 14 : 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: _pink, width: 4))),
                      child: Text(d.big!, style: body(story ? 16.5 : 15, w: FontWeight.w700, color: Colors.white, h: 1.4)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: _lime.withValues(alpha: .45), blurRadius: 16)]),
            child: Row(children: [
              Expanded(child: Text('তোমারটা বানাও →', style: body(14, w: FontWeight.w700, color: _ink, h: 1.2))),
            ]),
          ),
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown, child: Text('github.com/noor4964/chada-bazi · ব্যঙ্গ ও বিনোদন। আসল চাঁদাবাজি অপরাধ।', maxLines: 1, style: body(9, color: Colors.white54, h: 1.2))),
        ]),
      ),
      if (d.stamp != null) Positioned(right: 20, bottom: 36, child: _stampSticker(d.stamp!, fill: Colors.transparent, line: _lime, ink: _lime)),
    ]);
  }
}

// ----------------------------------------------------------------- y2k ----
// Hot-pink gradient, sparkles, outlined title and a retro window panel.

class _Y2k extends StatelessWidget {
  final ShareCardData d;
  final bool story;
  const _Y2k(this.d, this.story);

  static const _pink = Color(0xFFFF3CAC);
  static const _orange = Color(0xFFFF8A00);
  static const _sun = Color(0xFFFFE53B);

  @override
  Widget build(BuildContext context) {
    final st = stickersFor(d);
    final rng = math.Random(d.title.length * 7 + d.kicker.length);
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(
        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_pink, _orange, _sun]))),
      ),
      for (var i = 0; i < (story ? 9 : 6); i++)
        Positioned(
          left: 10 + rng.nextDouble() * 330,
          top: 8 + rng.nextDouble() * (story ? 610 : 420),
          child: Text(i.isEven ? '✦' : '✧', style: TextStyle(fontSize: 12 + rng.nextDouble() * 16, color: Colors.white.withValues(alpha: .85), height: 1)),
        ),
      Positioned(right: 4, top: story ? 112 : 76, child: _sticker(st[0], 42, .25)),
      Positioned(left: 4, top: story ? 300 : 210, child: _sticker(st[1], 30, -.3)),
      if (story) Positioned(right: 8, bottom: 124, child: _sticker(st[2], 34, .2)),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('চাঁদা বাজার', maxLines: 1, style: display(26, color: Colors.white).copyWith(shadows: const [Shadow(color: _ink, offset: Offset(2, 2))])),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _ink, width: 2), borderRadius: BorderRadius.circular(99)),
                child: Text(d.kicker, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, w: FontWeight.w700, color: _ink, h: 1.3)),
              ),
            ),
          ]),
          SizedBox(height: story ? 24 : 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 316,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(99)),
                      child: Text(povFor(d), style: body(13.5, w: FontWeight.w700, color: Colors.white, h: 1.25)),
                    ),
                  ),
                  SizedBox(height: story ? 16 : 8),
                  _outlined(d.title, story ? 32 : 24, Colors.white, _ink),
                  SizedBox(height: story ? 20 : 12),
                  if (d.rows.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _ink, width: 3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: _ink, offset: Offset(5, 5))],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: const BoxDecoration(color: _ink, borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
                          child: Row(children: [
                            for (final c in [_pink, _sun, Colors.white]) Container(width: 9, height: 9, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                            const Spacer(),
                            Text('chada_bazar.exe', style: body(10, color: Colors.white70, h: 1.2)),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                          child: _rows(d, label: _ink.withValues(alpha: .85), value: _pink, line: _ink.withValues(alpha: .15), size: story ? 13.5 : 12.5, vpad: story ? 5 : 3),
                        ),
                      ]),
                    ),
                  if (d.big != null) ...[
                    SizedBox(height: story ? 16 : 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _ink, width: 3), borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(3))),
                      child: Text(d.big!, style: body(story ? 16 : 14.5, w: FontWeight.w700, color: _ink, h: 1.4)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(99)),
            child: Row(children: [
              Expanded(child: Text('তোমারটা বানাও →', style: body(14, w: FontWeight.w700, color: _sun, h: 1.2))),
            ]),
          ),
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown, child: Text('github.com/noor4964/chada-bazi · ব্যঙ্গ ও বিনোদন। আসল চাঁদাবাজি অপরাধ।', maxLines: 1, style: body(9, color: _ink.withValues(alpha: .75), h: 1.2))),
        ]),
      ),
      if (d.stamp != null) Positioned(right: 18, bottom: 36, child: _stampSticker(d.stamp!, fill: _sun, line: _ink, ink: _ink, radius: BorderRadius.circular(99))),
    ]);
  }
}
