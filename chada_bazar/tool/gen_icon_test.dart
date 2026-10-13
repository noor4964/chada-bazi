// Draws the app icon art into assets/icon/ (needs the Nirmala font on Windows). Run:
//   flutter test tool/gen_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFC8102E);
const _yellow = Color(0xFFF7C600);
const _ink = Color(0xFF1C1A16);

void _coin(Canvas c, Offset center, double r, TextPainter glyph) {
  // Hard shadow, same style as the app's cards.
  c.drawCircle(center + Offset(r * .10, r * .10), r, Paint()..color = _ink);
  c.drawCircle(center, r, Paint()..color = _yellow);
  final rim = r * .09;
  c.drawCircle(center, r - rim / 2, Paint()..style = PaintingStyle.stroke..strokeWidth = rim..color = _ink);
  c.drawCircle(center, r * .80, Paint()..style = PaintingStyle.stroke..strokeWidth = r * .028..color = _ink);
  // The taka sign sits high in its line box; push it down to the coin's centre.
  glyph.paint(c, center - Offset(glyph.width / 2, glyph.height / 2) + Offset(0, r * .13));
}

Future<void> _save(String path, int size, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final img = await rec.endRecording().toImage(size, size);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate icon art', (tester) async {
    await tester.runAsync(() async {
      final font = File('C:/Windows/Fonts/NirmalaB.ttf').readAsBytesSync();
      final loader = FontLoader('NirmalaB')..addFont(Future.value(ByteData.sublistView(font)));
      await loader.load();

      TextPainter glyph(double size) => TextPainter(
            text: TextSpan(text: '৳', style: TextStyle(fontFamily: 'NirmalaB', fontSize: size, color: _ink, height: 1)),
            textDirection: TextDirection.ltr,
          )..layout();

      const s = 1024.0;
      // Full icon (legacy launchers, web favicon and PWA icons).
      await _save('assets/icon/icon.png', 1024, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, s, s), Paint()..color = _red);
        _coin(c, const Offset(s / 2 - 14, s / 2 - 14), 330, glyph(470));
      });
      // Foreground on transparent: kept inside the adaptive-icon safe zone.
      await _save('assets/icon/icon_foreground.png', 1024, (c) {
        _coin(c, const Offset(s / 2 - 12, s / 2 - 12), 270, glyph(385));
      });
    });
  });
}
