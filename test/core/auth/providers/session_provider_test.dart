import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/auth/repositories/roles_repository.dart';
import 'package:crs_ops/core/errors/app_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRolesRepository implements RolesRepository {
  _FakeRolesRepository({this.role = AppRole.admin, this.throwError = false});

  final AppRole? role;
  final bool throwError;

  @override
  Future<Set<String>> fetchModuleAccess(String userId) async => {'attendance'};

  @override
  Future<AppRole?> fetchRole(String userId) async {
    if (throwError) throw const DataException('denied');
    return role;
  }
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

    test(
      'a roles failure fails the session instead of a half-built one',
      () async {
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
            rolesRepositoryProvider.overrideWithValue(
              _FakeRolesRepository(throwError: true),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Riverpod 3 retries failed providers, so `.future` never settles —
        // assert on the emitted error state instead.
        AsyncValue<AppSession?>? latest;
        container.listen(sessionProvider, (_, next) => latest = next);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(latest, isNotNull);
        expect(latest!.hasError, isTrue);
        expect(latest!.error, isA<DataException>());
      },
    );

    test(
      'a null role passes through (router bounces to unauthorized)',
      () async {
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
            rolesRepositoryProvider.overrideWithValue(
              _FakeRolesRepository(role: null),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(sessionProvider.future);
        expect(result, isNotNull);
        expect(result!.role, isNull);
        expect(result.isAdminOrAbove, isFalse);
      },
    );
  });
}
