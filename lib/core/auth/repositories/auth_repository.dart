import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../../errors/exception_translator.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb || Platform.isLinux) {
        await _client.auth.signInWithOAuth(OAuthProvider.google);
      } else if (Platform.isAndroid) {
        await _signInWithGoogleNative();
      } else {
        throw const AuthFailureException('Google sign-in is not supported on this platform yet.');
      }
    } catch (error) {
      throw translateException(error);
    }
  }

  Future<void> _signInWithGoogleNative() async {
    // NOTE: requires the `google_sign_in` package's platform setup (OAuth client IDs
    // in Android's google-services.json) — see Task 19 Step 1's spike.
    throw UnimplementedError(
      'Wire up google_sign_in ID-token flow here in Task 19 once OAuth client IDs exist.',
    );
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw translateException(error);
    }
  }
}
