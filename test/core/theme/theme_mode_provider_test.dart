import 'package:crs_ops/core/data/shared_preferences_provider.dart';
import 'package:crs_ops/core/theme/theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ThemeModeController', () {
    test('defaults to system when nothing is saved', () async {
      final container = await _container({});
      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });

    test('restores a saved choice', () async {
      final container = await _container({'theme_mode': 'dark'});
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    });

    test('falls back to system for an unknown saved value', () async {
      final container = await _container({'theme_mode': 'sepia'});
      expect(container.read(themeModeControllerProvider), ThemeMode.system);
    });

    test('setting a mode updates state and persists it', () async {
      final container = await _container({});
      container.read(themeModeControllerProvider.notifier).set(ThemeMode.light);

      expect(container.read(themeModeControllerProvider), ThemeMode.light);
      await pumpEventQueue();
      expect(
        container.read(sharedPreferencesProvider).getString('theme_mode'),
        'light',
      );
    });
  });
}
