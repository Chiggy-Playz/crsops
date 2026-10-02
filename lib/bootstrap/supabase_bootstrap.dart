import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  // Eager throw, not assert: asserts are stripped in release, which would
  // silently init Supabase with empty strings and fail opaquely later.
  if (url.isEmpty || key.isEmpty) {
    throw StateError(
      'Missing --dart-define SUPABASE_URL and/or SUPABASE_PUBLISHABLE_KEY.',
    );
  }
  await Supabase.initialize(url: url, publishableKey: key);
}
