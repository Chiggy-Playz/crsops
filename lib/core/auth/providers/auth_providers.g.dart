// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'2f243b04dd88d4803e0fb0a51d03fefcc7e7d876';

@ProviderFor(rolesRepository)
final rolesRepositoryProvider = RolesRepositoryProvider._();

final class RolesRepositoryProvider
    extends
        $FunctionalProvider<RolesRepository, RolesRepository, RolesRepository>
    with $Provider<RolesRepository> {
  RolesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rolesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rolesRepositoryHash();

  @$internal
  @override
  $ProviderElement<RolesRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RolesRepository create(Ref ref) {
    return rolesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RolesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RolesRepository>(value),
    );
  }
}

String _$rolesRepositoryHash() => r'ddd7d7709733fd60dbca7000883c9a4107ce8d2a';

@ProviderFor(authStateChanges)
final authStateChangesProvider = AuthStateChangesProvider._();

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'1ec122a0e26f12799ddc86e77bd48fab67af3a4f';

@ProviderFor(session)
final sessionProvider = SessionProvider._();

final class SessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSession?>,
          AppSession?,
          FutureOr<AppSession?>
        >
    with $FutureModifier<AppSession?>, $FutureProvider<AppSession?> {
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  $FutureProviderElement<AppSession?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppSession?> create(Ref ref) {
    return session(ref);
  }
}

String _$sessionHash() => r'31100c34613219dd82ccf37b6da37f1d5b935102';
