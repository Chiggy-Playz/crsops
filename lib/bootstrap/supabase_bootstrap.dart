import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    // anonKey is deprecated in this supabase_flutter version in favor of
    // publishableKey (same underlying Supabase key, renamed parameter) — found via
    // dart analyze, not the plan, which still used the old name.
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
}
