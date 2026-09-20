import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/auth/repositories/roles_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRolesRepository implements RolesRepository {
  @override
  Future<Set<String>> fetchModuleAccess(String userId) async => {'attendance'};

  @override
  Future<AppRole?> fetchRole(String userId) async => AppRole.admin;
}

User _user() => const User(
  id: 'u1',
  appMetadata: {},
  userMetadata: {},
  aud: '',
  createdAt: '',
  email: 'dad@example.com',
  isAnonymous: false,
);

void main() {
  group('sessionProvider', () {
    test('composes role and module access onto the signed-in user', () async {
      final session = Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: _user(),
      );
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(AuthState(AuthChangeEvent.signedIn, session)),
          ),
          rolesRepositoryProvider.overrideWithValue(_FakeRolesRepository()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(sessionProvider.future);

      expect(result, isNotNull);
      expect(result!.userId, 'u1');
      expect(result.email, 'dad@example.com');
      expect(result.role, AppRole.admin);
      expect(result.moduleAccess, {'attendance'});
      expect(result.isAdminOrAbove, isTrue);
    });

    test('signed out means no session', () async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWithValue(
            AsyncValue.data(AuthState(AuthChangeEvent.signedOut, null)),
          ),
          rolesRepositoryProvider.overrideWithValue(_FakeRolesRepository()),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(sessionProvider.future), isNull);
    });
  });
}
