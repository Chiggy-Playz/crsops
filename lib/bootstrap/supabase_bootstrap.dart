import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
}
