import 'package:flutter/material.dart';

/// Minimal placeholder theme — swap in your real design tokens (type
/// scale, accent color picker wiring, spacing system) during the UI
/// polish pass.
class ChompTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );
}
