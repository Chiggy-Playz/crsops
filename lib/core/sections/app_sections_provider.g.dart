// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_sections_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every section, in nav order. Core can't build this list itself (that would
/// mean importing modules), so `main.dart` overrides it with `allSections`
/// from the composition root; tests override it with whatever they need.

@ProviderFor(appSections)
final appSectionsProvider = AppSectionsProvider._();

/// Every section, in nav order. Core can't build this list itself (that would
/// mean importing modules), so `main.dart` overrides it with `allSections`
/// from the composition root; tests override it with whatever they need.

final class AppSectionsProvider
    extends
        $FunctionalProvider<
          List<AppSection>,
          List<AppSection>,
          List<AppSection>
        >
    with $Provider<List<AppSection>> {
  /// Every section, in nav order. Core can't build this list itself (that would
  /// mean importing modules), so `main.dart` overrides it with `allSections`
  /// from the composition root; tests override it with whatever they need.
  AppSectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSectionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSectionsHash();

  @$internal
  @override
  $ProviderElement<List<AppSection>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<AppSection> create(Ref ref) {
    return appSections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<AppSection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<AppSection>>(value),
    );
  }
}

String _$appSectionsHash() => r'9c4907f074f2442f215d7af6fc1912fd8dfc7299';
