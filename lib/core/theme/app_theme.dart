import 'package:flutter/material.dart';

import 'custom_colors.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final colorScheme = ColorScheme.fromSeed(
    // Material blue, with the default tonalSpot variant: a calm steel blue.
    // (fidelity keeps the seed's full saturation — tried, too loud.)
    seedColor: const Color(0xFF2196F3),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [AppColors.forScheme(colorScheme)],
    // Bare TextField/DropdownMenu default to Material 2's underline style even
    // with useMaterial3: true — M3's outlined look is opt-in, not automatic.
    // Outlined variant: no fill, full border on all sides at rest (outline
    // color), all 4 corners rounded, thicker primary border when focused.
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    // Default ListTile title/subtitle styles read too similarly at a glance —
    // give the title real weight and keep the subtitle clearly secondary.
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
