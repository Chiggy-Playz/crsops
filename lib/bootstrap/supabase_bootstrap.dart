import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  assert(
    url.isNotEmpty && key.isNotEmpty,
    'Missing --dart-define SUPABASE_URL and/or SUPABASE_PUBLISHABLE_KEY; '
    'Supabase.initialize would fail opaquely without them.',
  );
  await Supabase.initialize(url: url, publishableKey: key);
}
