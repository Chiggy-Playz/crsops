import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../modules/attendance/routes.dart';
import '../../modules/settings/routes.dart';
import '../employees/routes.dart';
import '../auth/pages/loading_page.dart';
import '../auth/pages/sign_in_page.dart';
import '../auth/pages/unauthorized_page.dart';
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
    initialLocation: loadingPath,
    redirect: (context, state) {
      final sessionValue = ref.read(sessionProvider);
      return computeRedirect(sessionValue: sessionValue, currentLocation: state.matchedLocation);
    },
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(path: loadingPath, builder: (context, state) => const LoadingPage()),
      GoRoute(path: signInPath, builder: (context, state) => const SignInPage()),
      GoRoute(path: unauthorizedPath, builder: (context, state) => const UnauthorizedPage()),
      ...employeeRoutes(ref),
      ...attendanceRoutes(ref),
      ...settingsRoutes(ref),
    ],
  );
}

/// Bridges Riverpod provider changes (via ref.listen) to GoRouter's
/// Listenable-based refresh API.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
