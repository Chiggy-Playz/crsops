import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:crs_ops/core/auth/pages/sign_in_page.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/widgets/app_snack_bar.dart';

void main() {
  testWidgets('a sign-in error that came back in the redirect is shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            const AsyncValue<AuthState>.error(
              AuthException('Sign-up not permitted for this email address.'),
              StackTrace.empty,
            ),
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          home: const SignInPage(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Sign-up not permitted for this email address.'),
      findsOneWidget,
    );
  });
}
