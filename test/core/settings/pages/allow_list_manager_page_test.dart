import 'package:crs_ops/core/auth/models/profile.dart';
import 'package:crs_ops/core/auth/providers/admin_providers.dart';
import 'package:crs_ops/core/auth/repositories/admin_repository.dart';
import 'package:crs_ops/core/settings/pages/allow_list_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminRepository implements AdminRepository {
  String? addedEmail;

  @override
  Future<void> addAllowedEmail({required String email, String? note}) async {
    addedEmail = email;
  }

  @override
  Future<List<({String email, String? note, DateTime addedAt})>>
  fetchAllowedEmails() async => [];

  @override
  Future<void> removeAllowedEmail(String email) async {}

  @override
  Future<List<Profile>> fetchProfiles() async => [];

  @override
  Future<Map<String, String>> fetchUserRoles() async => {};

  @override
  Future<void> grantRole({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<void> revokeRole({
    required String userId,
    required String roleId,
  }) async {}

  @override
  Future<List<({String id, String name})>> fetchModules() async => [];

  @override
  Future<Map<String, Set<String>>> fetchModuleAccess() async => {};

  @override
  Future<void> grantModuleAccess({
    required String userId,
    required String moduleId,
  }) async {}
}

void main() {
  group('AllowListManagerPage', () {
    testWidgets('added emails are stored lowercase', (tester) async {
      final adminRepo = _FakeAdminRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [adminRepositoryProvider.overrideWithValue(adminRepo)],
          child: const MaterialApp(home: AllowListManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Email').first,
        'DAD@Example.COM',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(adminRepo.addedEmail, 'dad@example.com');
    });
  });
}
