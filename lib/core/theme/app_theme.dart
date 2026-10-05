import 'package:flutter/material.dart';

import 'custom_colors.dart';

/// M3's small top app bar height. Flutter's plain AppBar defaults to 56
/// (kToolbarHeight); M3 specifies 64, which also gives web/desktop — where
/// there's no status bar above it — some breathing room.
const appBarHeight = 64.0;

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
    // Flutter defaults desktop platforms (including web on a desktop OS) to
    // compact density — shorter rows, smaller buttons — so the browser looked
    // cramped next to the phone. Same density everywhere.
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(toolbarHeight: appBarHeight),
    // Floating everywhere, so no call site has to ask for it.
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
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
        // M3 titles are 500. (600 also rendered as bold on web, where the
        // bundled Roboto has no 600 and rounds up to 700.)
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
