import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:crs_ops/core/auth/providers/admin_providers.dart';
import 'package:crs_ops/modules/settings/pages/roles_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/auth/fakes/fake_admin_repository.dart';

Profile _profile(String id, String email) =>
    Profile(id: id, email: email, createdAt: DateTime(2024));

void main() {
  group('RolesManagerPage', () {
    testWidgets('lists profiles with their granted roles', (tester) async {
      final repo = FakeAdminRepository(
        profiles: [_profile('u1', 'a@x.com'), _profile('u2', 'b@x.com')],
        roles: {'u1': 'admin'},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: RolesManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('a@x.com'), findsOneWidget);
      expect(find.text('Role: Admin'), findsOneWidget);
      expect(find.text('No role granted'), findsOneWidget);
    });

    testWidgets('changing a role revokes then grants', (tester) async {
      final repo = FakeAdminRepository(
        profiles: [_profile('u1', 'a@x.com')],
        roles: {'u1': 'admin'},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: RolesManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('a@x.com'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('employee').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.revokedRoles, contains((userId: 'u1', roleId: 'admin')));
      expect(
        repo.grantedRoles,
        contains((userId: 'u1', roleId: 'employee')),
      );
    });
  });
}
