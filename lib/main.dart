import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/supabase_bootstrap.dart';
import 'core/logging/app_talker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAppTalker();
  await bootstrapSupabase();
  runApp(const ProviderScope(child: App()));
}
