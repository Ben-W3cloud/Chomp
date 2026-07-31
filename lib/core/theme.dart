import 'package:flutter/material.dart';

class ChompTheme {
  /// Light mode theme configuration.
  /// Uses Material 3 with a purple accent color.
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );

  /// Dark mode theme configuration.
  /// Uses Material 3 with the same purple accent color for consistency.
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C5CE7),
      );
}
