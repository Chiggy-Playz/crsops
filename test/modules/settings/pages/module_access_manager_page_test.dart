import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:crs_ops/core/auth/providers/admin_providers.dart';
import 'package:crs_ops/modules/settings/pages/module_access_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/auth/fakes/fake_admin_repository.dart';

void main() {
  group('ModuleAccessManagerPage', () {
    testWidgets('lists profiles with their granted modules', (tester) async {
      final repo = FakeAdminRepository(
        profiles: [
          Profile(id: 'u1', email: 'a@x.com', createdAt: DateTime(2024)),
        ],
        modules: [(id: 'attendance', name: 'Attendance')],
        access: {
          'u1': {'attendance'},
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: ModuleAccessManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('a@x.com'), findsOneWidget);
      expect(find.text('attendance'), findsOneWidget);
    });

    testWidgets('granting access records the module', (tester) async {
      final repo = FakeAdminRepository(
        profiles: [
          Profile(id: 'u1', email: 'a@x.com', createdAt: DateTime(2024)),
        ],
        modules: [(id: 'attendance', name: 'Attendance')],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: ModuleAccessManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No module access granted'), findsOneWidget);

      await tester.tap(find.text('a@x.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attendance').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grant'));
      await tester.pumpAndSettle();

      expect(
        repo.grantedAccess,
        contains((userId: 'u1', moduleId: 'attendance')),
      );
    });
  });
}
