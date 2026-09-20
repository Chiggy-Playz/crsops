// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Online state with an explicit initial check, live broadcast updates, and
/// a manual re-check for the offline screen's Retry button.
///
/// A bare broadcast stream was not enough: it emits nothing on first listen
/// (so the UI only ever saw "online" until the first *change*), and
/// invalidating it for Retry just re-subscribed to the same silent stream.

@ProviderFor(IsOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Online state with an explicit initial check, live broadcast updates, and
/// a manual re-check for the offline screen's Retry button.
///
/// A bare broadcast stream was not enough: it emits nothing on first listen
/// (so the UI only ever saw "online" until the first *change*), and
/// invalidating it for Retry just re-subscribed to the same silent stream.
final class IsOnlineProvider extends $AsyncNotifierProvider<IsOnline, bool> {
  /// Online state with an explicit initial check, live broadcast updates, and
  /// a manual re-check for the offline screen's Retry button.
  ///
  /// A bare broadcast stream was not enough: it emits nothing on first listen
  /// (so the UI only ever saw "online" until the first *change*), and
  /// invalidating it for Retry just re-subscribed to the same silent stream.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  IsOnline create() => IsOnline();
}

String _$isOnlineHash() => r'0cf68033f2af61e31a68a0122120b4aabaaf3e41';

/// Online state with an explicit initial check, live broadcast updates, and
/// a manual re-check for the offline screen's Retry button.
///
/// A bare broadcast stream was not enough: it emits nothing on first listen
/// (so the UI only ever saw "online" until the first *change*), and
/// invalidating it for Retry just re-subscribed to the same silent stream.

abstract class _$IsOnline extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
