import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_sections.dart';
import 'bootstrap/supabase_bootstrap.dart';
import 'core/data/shared_preferences_provider.dart';
import 'core/logging/app_talker.dart';
import 'core/sections/app_sections_provider.dart';

Future<void> main() async {
  // Web: clean URLs (/employees/…, no #). A production host must serve
  // index.html for every path (single-page-app fallback).
  usePathUrlStrategy();
  // Pushed pages update the address bar too. Two-pane layouts select their
  // right pane from the URL, so it has to stay accurate.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  WidgetsFlutterBinding.ensureInitialized();
  await initAppTalker();
  await bootstrapSupabase();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        appSectionsProvider.overrideWithValue(allSections),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
