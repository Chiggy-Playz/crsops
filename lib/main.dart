import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_sections.dart';
import 'bootstrap/supabase_bootstrap.dart';
import 'core/data/shared_preferences_provider.dart';
import 'core/logging/app_talker.dart';
import 'core/sections/app_sections_provider.dart';

Future<void> main() async {
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
