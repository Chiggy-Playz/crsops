// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateRepository)
final updateRepositoryProvider = UpdateRepositoryProvider._();

final class UpdateRepositoryProvider
    extends
        $FunctionalProvider<
          UpdateRepository,
          UpdateRepository,
          UpdateRepository
        >
    with $Provider<UpdateRepository> {
  UpdateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateRepositoryHash();

  @$internal
  @override
  $ProviderElement<UpdateRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateRepository create(Ref ref) {
    return updateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateRepository>(value),
    );
  }
}

String _$updateRepositoryHash() => r'6a4794a35d7d1f22101f86401cb153e0b5b24431';

@ProviderFor(UpdateController)
final updateControllerProvider = UpdateControllerProvider._();

final class UpdateControllerProvider
    extends $NotifierProvider<UpdateController, UpdateState> {
  UpdateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateControllerHash();

  @$internal
  @override
  UpdateController create() => UpdateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateState>(value),
    );
  }
}

String _$updateControllerHash() => r'7d34db913e26c4dda99528a9062c03ba2781db3b';

abstract class _$UpdateController extends $Notifier<UpdateState> {
  UpdateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateState, UpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateState, UpdateState>,
              UpdateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
