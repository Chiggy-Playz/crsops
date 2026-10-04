import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Material 3 "custom color" roles — the same four roles every built-in color
/// has (primary / onPrimary / primaryContainer / onPrimaryContainer), for an
/// extra color like "success" or a status color from the database.
///
/// - [color]: strong fills (dots, badges, icons)
/// - [onColor]: text/icons on [color]
/// - [colorContainer]: soft fills (chips, tonal buttons)
/// - [onColorContainer]: text/icons on [colorContainer]
@immutable
class CustomColorRoles {
  const CustomColorRoles({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;

  static CustomColorRoles lerp(
    CustomColorRoles a,
    CustomColorRoles b,
    double t,
  ) => CustomColorRoles(
    color: Color.lerp(a.color, b.color, t)!,
    onColor: Color.lerp(a.onColor, b.onColor, t)!,
    colorContainer: Color.lerp(a.colorContainer, b.colorContainer, t)!,
    onColorContainer: Color.lerp(a.onColorContainer, b.onColorContainer, t)!,
  );
}

final _cache = <(int, int, Brightness), CustomColorRoles>{};

/// Builds the four roles for [seed] in the given scheme, following M3's custom
/// color recipe (as in material-color-utilities' `customColor`):
///
/// 1. Harmonize: nudge the hue toward the app's primary so it sits with the
///    theme, while still reading as the same color (green stays green).
/// 2. Tonal palette from the harmonized hue, at chroma ≥ 48 so it stays vivid.
///    Near-greys (e.g. Week off) keep their low chroma instead of being
///    turned into a colour. Containers come from a calmer chroma-36 palette —
///    the same chroma ColorScheme.fromSeed uses for primaryContainer — because
///    at tone 90 green can reach far more chroma than red, so the vivid recipe
///    gives a loud mint next to a pale pink.
/// 3. Pick tones per brightness — light: 40 / 100 / 90 / 10,
///    dark: 80 / 20 / 30 / 90 — which is what makes containers pastel in light
///    mode and deep-but-readable in dark mode.
CustomColorRoles customColorRoles(Color seed, ColorScheme scheme) {
  final key = (seed.toARGB32(), scheme.primary.toARGB32(), scheme.brightness);
  return _cache.putIfAbsent(key, () {
    final harmonized = Blend.harmonize(
      seed.toARGB32(),
      scheme.primary.toARGB32(),
    );
    final hct = Hct.fromInt(harmonized);
    final isNeutral = hct.chroma < 12;
    final strong = TonalPalette.of(
      hct.hue,
      isNeutral ? hct.chroma : math.max(hct.chroma, 48.0),
    );
    final container = TonalPalette.of(hct.hue, isNeutral ? hct.chroma : 36.0);
    Color s(int t) => Color(strong.get(t));
    Color c(int t) => Color(container.get(t));

    return scheme.brightness == Brightness.light
        ? CustomColorRoles(
            color: s(40),
            onColor: s(100),
            colorContainer: c(90),
            onColorContainer: c(10),
          )
        : CustomColorRoles(
            color: s(80),
            onColor: s(20),
            colorContainer: c(30),
            onColorContainer: c(90),
          );
  });
}

/// App-wide extra colors, attached to ThemeData so they switch with
/// light/dark like `colorScheme`. Read with `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.warning});

  factory AppColors.forScheme(ColorScheme scheme) => AppColors(
    success: customColorRoles(const Color(0xFF4CAF50), scheme),
    warning: customColorRoles(const Color(0xFFFFA000), scheme),
  );

  final CustomColorRoles success;
  final CustomColorRoles warning;

  @override
  AppColors copyWith({CustomColorRoles? success, CustomColorRoles? warning}) =>
      AppColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  AppColors lerp(AppColors? other, double t) => other == null
      ? this
      : AppColors(
          success: CustomColorRoles.lerp(success, other.success, t),
          warning: CustomColorRoles.lerp(warning, other.warning, t),
        );
}

extension CustomColorsContext on BuildContext {
  /// Falls back to deriving from the current scheme when the theme doesn't
  /// carry the extension (e.g. a bare MaterialApp in tests).
  AppColors get appColors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        AppColors.forScheme(theme.colorScheme);
  }

  /// Roles for a color only known at runtime (e.g. a status type's color_hex),
  /// tuned to the current theme. Cached, so cheap to call in build.
  CustomColorRoles customColor(Color seed) =>
      customColorRoles(seed, Theme.of(this).colorScheme);
}
