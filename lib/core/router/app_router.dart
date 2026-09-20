import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../modules/attendance/routes.dart' as attendance_routes;
import '../../modules/settings/routes.dart' as settings_routes;
import '../employees/routes.dart' as employee_routes;
import 'auth_routes.dart' as auth_routes;
import '../auth/providers/auth_providers.dart';
import 'redirect_logic.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Riverpod 3.x's generated FutureProvider-style providers only expose `.future`,
  // not `.stream` (that existed in 2.x but was removed) — bridge session changes to
  // GoRouter's Listenable-based refresh API via ref.listen instead, which works
  // regardless of the underlying provider type.
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(sessionProvider, (previous, next) => refreshNotifier.refresh());

  return GoRouter(
    initialLocation: const auth_routes.LoadingRoute().location,
    redirect: (context, state) {
      final sessionValue = ref.read(sessionProvider);
      return computeRedirect(
        sessionValue: sessionValue,
        currentLocation: state.matchedLocation,
      );
    },
    refreshListenable: refreshNotifier,
    // Each route file generates its own $appRoutes list (go_router_builder
    // is per-library); merged here, which is also the module boundary —
    // adding a module means one import plus one spread line.
    routes: [
      ...auth_routes.$appRoutes,
      ...employee_routes.$appRoutes,
      ...attendance_routes.$appRoutes,
      ...settings_routes.$appRoutes,
    ],
  );
}

/// Bridges Riverpod provider changes (via ref.listen) to GoRouter's
/// Listenable-based refresh API.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
