import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../../errors/exception_translator.dart';

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  // GoogleSignIn.instance.initialize() must be called exactly once per app run
  // (calling it more than once is undefined behavior per the package docs) —
  // memoized here rather than in bootstrap so this file stays self-contained.
  static Future<void>? _googleSignInInitialization;

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
    // NOTE: cannot be exercised end-to-end until a real Android device/emulator is
    // available. Also still needs a separate Android-type OAuth client registered in
    // Google Cloud Console (app's package name + SHA-1 signing fingerprint) — no code
    // involved, but native sign-in fails on-device without it even with the correct
    // serverClientId. Code compiles against the actual installed google_sign_in 7.x API
    // (verified against package source — the plan's original code targeted the pre-7.x
    // API, which no longer exists: no unnamed GoogleSignIn() constructor, no .signIn()
    // method); Task 19 Step 1's spike (confirming a non-null idToken on a real device)
    // still needs doing for real.
    // serverClientId must be the Web OAuth client ID (the same one pasted into
    // Supabase's Google provider config) — it's what sets the ID token's audience,
    // which Supabase checks when verifying the token in signInWithIdToken below.
    // Without it, Supabase rejects the token even though native sign-in succeeds.
    _googleSignInInitialization ??= GoogleSignIn.instance.initialize(
      serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    );
    await _googleSignInInitialization;

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw AuthFailureException('Google sign-in failed: ${e.description ?? e.code}');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailureException('Google sign-in did not return an ID token.');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
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
