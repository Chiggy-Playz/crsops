import 'package:crs_ops/app_sections.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/data/shared_preferences_provider.dart';
import 'package:crs_ops/core/sections/app_sections_provider.dart';
import 'package:crs_ops/core/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

Widget _wrap(AppRole? role) => ProviderScope(
  overrides: [
    appSectionsProvider.overrideWithValue(allSections),
    sharedPreferencesProvider.overrideWithValue(_prefs),
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('SettingsPage menu gating', () {
    // Tall enough that every group is built — the default 800x600 test
    // window leaves the last groups past ListView's lazy build area.
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(800, 1600);
      view.devicePixelRatio = 1;
      addTearDown(view.reset);
    });

    testWidgets('superadmin sees every admin section', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.superadmin));
      await tester.pumpAndSettle();

      for (final label in [
        'Signup allow-list',
        'Roles',
        'Module access',
        'Event types',
        'Shift defaults',
        'Status types',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('admin sees operational sections only', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.admin));
      await tester.pumpAndSettle();

      for (final label in ['Module access', 'Shift defaults', 'Status types']) {
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
        'Status types',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(find.text('Sign out'), findsOneWidget);
    });
  });

  group('SettingsPage groups', () {
    setUp(() {
      final view =
          TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(800, 1600);
      view.devicePixelRatio = 1;
      addTearDown(view.reset);
    });

    testWidgets('a group with no visible entries is hidden', (tester) async {
      // Admin can't see Event types (superadmin-only), so the Employees group
      // has nothing to show.
      await tester.pumpWidget(_wrap(AppRole.admin));
      await tester.pumpAndSettle();

      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Employees'), findsNothing);
    });

    testWidgets('employee sees only Appearance and Sign out', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.employee));
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      for (final header in ['Access', 'Attendance', 'Employees']) {
        expect(find.text(header), findsNothing);
      }
    });

    testWidgets('Access comes before the module groups', (tester) async {
      await tester.pumpWidget(_wrap(AppRole.superadmin));
      await tester.pumpAndSettle();

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('Appearance'), lessThan(top('Access')));
      expect(top('Access'), lessThan(top('Attendance')));
      expect(top('Attendance'), lessThan(top('Employees')));
    });
  });

  group('SettingsPage theme row', () {
    testWidgets('shows the current choice and changes it via the sheet', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(AppRole.employee));
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget); // the row's subtitle
      expect(find.text('System default'), findsNothing);
      expect(_prefs.getString('theme_mode'), 'dark');
    });
  });
}
