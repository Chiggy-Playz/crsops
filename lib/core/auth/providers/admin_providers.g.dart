// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'f2019e2eb6d7c18f77cb02e6be9c4fa22bb1be97';

@ProviderFor(allowedEmails)
final allowedEmailsProvider = AllowedEmailsProvider._();

final class AllowedEmailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({DateTime addedAt, String email, String? note})>>,
          List<({DateTime addedAt, String email, String? note})>,
          FutureOr<List<({DateTime addedAt, String email, String? note})>>
        >
    with
        $FutureModifier<List<({DateTime addedAt, String email, String? note})>>,
        $FutureProvider<
          List<({DateTime addedAt, String email, String? note})>
        > {
  AllowedEmailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allowedEmailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allowedEmailsHash();

  @$internal
  @override
  $FutureProviderElement<List<({DateTime addedAt, String email, String? note})>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({DateTime addedAt, String email, String? note})>> create(
    Ref ref,
  ) {
    return allowedEmails(ref);
  }
}

String _$allowedEmailsHash() => r'5d04930a340baae954b427b3d69ee14ec4d4813a';

@ProviderFor(profiles)
final profilesProvider = ProfilesProvider._();

final class ProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Profile>>,
          List<Profile>,
          FutureOr<List<Profile>>
        >
    with $FutureModifier<List<Profile>>, $FutureProvider<List<Profile>> {
  ProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilesHash();

  @$internal
  @override
  $FutureProviderElement<List<Profile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Profile>> create(Ref ref) {
    return profiles(ref);
  }
}

String _$profilesHash() => r'c43c49a9c636cbc94cba1a7e957329eeb05df6d8';

@ProviderFor(userRoles)
final userRolesProvider = UserRolesProvider._();

final class UserRolesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  UserRolesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRolesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRolesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return userRoles(ref);
  }
}

String _$userRolesHash() => r'2c02732e4b5f1a8b0a0bb25c419e5a27d5502ad2';

@ProviderFor(modules)
final modulesProvider = ModulesProvider._();

final class ModulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({String id, String name})>>,
          List<({String id, String name})>,
          FutureOr<List<({String id, String name})>>
        >
    with
        $FutureModifier<List<({String id, String name})>>,
        $FutureProvider<List<({String id, String name})>> {
  ModulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modulesHash();

  @$internal
  @override
  $FutureProviderElement<List<({String id, String name})>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({String id, String name})>> create(Ref ref) {
    return modules(ref);
  }
}

String _$modulesHash() => r'4a5d3f2bc1bcfe85a69c23366a54da7762a27948';

@ProviderFor(moduleAccess)
final moduleAccessProvider = ModuleAccessProvider._();

final class ModuleAccessProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Set<String>>>,
          Map<String, Set<String>>,
          FutureOr<Map<String, Set<String>>>
        >
    with
        $FutureModifier<Map<String, Set<String>>>,
        $FutureProvider<Map<String, Set<String>>> {
  ModuleAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moduleAccessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moduleAccessHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Set<String>>> create(Ref ref) {
    return moduleAccess(ref);
  }
}

String _$moduleAccessHash() => r'06788547739caf50ab85e7a4d0492bb850b1f45c';
