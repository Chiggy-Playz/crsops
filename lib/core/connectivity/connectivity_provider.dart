import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Online state with an explicit initial check, live broadcast updates, and
/// a manual re-check for the offline screen's Retry button.
///
/// A bare broadcast stream was not enough: it emits nothing on first listen
/// (so the UI only ever saw "online" until the first *change*), and
/// invalidating it for Retry just re-subscribed to the same silent stream.
@riverpod
class IsOnline extends _$IsOnline {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<bool> build() async {
    final current = await Connectivity().checkConnectivity();
    _subscription ??= Connectivity().onConnectivityChanged.listen(
      (results) => state = AsyncData(_isOnline(results)),
    );
    ref.onDispose(() => _subscription?.cancel());
    return _isOnline(current);
  }

  /// Re-checks connectivity on demand. Null (loading) during the check so
  /// the UI keeps its current treatment instead of flickering.
  Future<void> retry() async {
    state = const AsyncLoading();
    try {
      final current = await Connectivity().checkConnectivity();
      state = AsyncData(_isOnline(current));
    } catch (_) {
      state = const AsyncData(false);
    }
  }

  static bool _isOnline(List<ConnectivityResult> results) =>
      !results.contains(ConnectivityResult.none);
}
