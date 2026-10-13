import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Street-banner palette: red, bottle green, signboard yellow, newsprint.
class Palette {
  final Color paper, surface, ink, muted, line, red, redInk, green, greenInk, yellow, yellowInk;
  const Palette({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.red,
    required this.redInk,
    required this.green,
    required this.greenInk,
    required this.yellow,
    required this.yellowInk,
  });

  static const light = Palette(
    paper: Color(0xFFF2ECD9),
    surface: Color(0xFFFFFBEF),
    ink: Color(0xFF1C1A16),
    muted: Color(0xFF5E5847),
    line: Color(0xFFD8CFB4),
    red: Color(0xFFC8102E),
    redInk: Color(0xFFFFFFFF),
    green: Color(0xFF0B5D3B),
    greenInk: Color(0xFFF2ECD9),
    yellow: Color(0xFFF7C600),
    yellowInk: Color(0xFF1C1A16),
  );

  static const dark = Palette(
    paper: Color(0xFF16140F),
    surface: Color(0xFF211E17),
    ink: Color(0xFFF2ECD9),
    muted: Color(0xFFB4AB92),
    line: Color(0xFF3A3528),
    red: Color(0xFFE8364F),
    redInk: Color(0xFFFFFFFF),
    green: Color(0xFF2E9C6A),
    greenInk: Color(0xFF0F0E0A),
    yellow: Color(0xFFFFD23F),
    yellowInk: Color(0xFF16140F),
  );

  static Palette of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;
}

TextStyle display(double size, {Color? color}) =>
    GoogleFonts.galada(fontSize: size, color: color, height: 1.1);

TextStyle body(double size, {FontWeight w = FontWeight.w500, Color? color, double h = 1.5}) =>
    GoogleFonts.hindSiliguri(fontSize: size, fontWeight: w, color: color, height: h);

ThemeData buildTheme(Palette p, Brightness b) {
  final base = ThemeData(brightness: b, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: p.red, brightness: b).copyWith(
      surface: p.surface,
      primary: p.red,
      onPrimary: p.redInk,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.hindSiliguri().fontFamily,
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.paper,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.ink, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.ink, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.yellow, width: 3),
      ),
      labelStyle: TextStyle(color: p.muted),
    ),
  );
}
