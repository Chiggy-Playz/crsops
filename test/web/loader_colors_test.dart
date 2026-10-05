import 'dart:io';

import 'package:crs_ops/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// web/index.html shows a spinner while Flutter downloads, then Flutter's
/// LoadingPage replaces it. The swap is only invisible if the hard-coded
/// colors there match the app theme, so this fails when the theme changes.
void main() {
  final html = File('web/index.html').readAsStringSync();

  String cssColor(String name) {
    final match = RegExp('--$name:\\s*#([0-9a-fA-F]{6})').firstMatch(html);
    if (match == null) {
      fail('web/index.html has no --$name color');
    }
    return match.group(1)!.toLowerCase();
  }

  String hex(Color color) =>
      (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

  for (final brightness in Brightness.values) {
    test('loader colors match the ${brightness.name} theme', () {
      final scheme = buildAppTheme(brightness: brightness).colorScheme;
      expect(cssColor('loader-bg-${brightness.name}'), hex(scheme.surface));
      expect(cssColor('loader-fg-${brightness.name}'), hex(scheme.primary));
    });
  }
}
