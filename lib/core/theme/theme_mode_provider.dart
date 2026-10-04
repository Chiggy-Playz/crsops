import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/shared_preferences_provider.dart';
import '../logging/app_talker.dart';

part 'theme_mode_provider.g.dart';

const _themeModeKey = 'theme_mode';

/// The user's System / Light / Dark choice, persisted per device.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_themeModeKey);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    // Cosmetic preference: if the write fails the choice still holds for this
    // session, so log it rather than bother the user.
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(_themeModeKey, mode.name)
          .catchError((Object e, StackTrace st) {
            appTalker.handle(e, st, 'Saving theme mode failed');
            return false;
          }),
    );
  }
}
