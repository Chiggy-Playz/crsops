import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/modules/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(AppRole? role) => ProviderScope(
  overrides: [
    sessionProvider.overrideWithValue(
      AsyncValue.data(
        AppSession(
          userId: 'u1',
          email: 'a@x.com',
          role: role,
          moduleAccess: {},
        ),
      ),
    ),
  ],
  child: const MaterialApp(home: SettingsPage()),
);

void main() {
  group('SettingsPage menu gating', () {
    testWidgets('superadmin sees every admin section', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.superadmin));
      await tester.pumpAndSettle();

      for (final label in [
        'Signup allow-list',
        'Roles',
        'Module access',
        'Event types',
        'Shift defaults',
        'Attendance status types',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('admin sees operational sections only', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.admin));
      await tester.pumpAndSettle();

      for (final label in [
        'Module access',
        'Shift defaults',
        'Attendance status types',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      for (final label in ['Signup allow-list', 'Roles', 'Event types']) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('employee sees no admin sections', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.employee));
      await tester.pumpAndSettle();

      for (final label in [
        'Signup allow-list',
        'Roles',
        'Module access',
        'Event types',
        'Shift defaults',
        'Attendance status types',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
