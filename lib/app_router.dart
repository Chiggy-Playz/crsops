import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'core/auth/providers/auth_providers.dart';
import 'core/router/auth_routes.dart' as auth_routes;
import 'core/router/navigator_keys.dart';
import 'core/router/redirect_logic.dart';
import 'core/sections/app_sections_provider.dart';
import 'core/sections/section_nav_shell.dart';
import 'core/settings/settings_section.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final sections = ref.watch(appSectionsProvider);

  // Riverpod 3.x's generated FutureProvider-style providers only expose `.future`,
  // not `.stream` (that existed in 2.x but was removed) — bridge session changes to
  // GoRouter's Listenable-based refresh API via ref.listen instead, which works
  // regardless of the underlying provider type.
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(sessionProvider, (previous, next) => refreshNotifier.refresh());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: const auth_routes.LoadingRoute().location,
    redirect: (context, state) => computeRedirect(
      sessionValue: ref.read(sessionProvider),
      currentLocation: state.matchedLocation,
      sections: sections,
    ),
    refreshListenable: refreshNotifier,
    routes: [
      ...auth_routes.$appRoutes,
      // One branch per section, each with its own navigation stack. Built by
      // hand rather than with @TypedStatefulShellRoute, which needs the whole
      // tree in one annotated file — each section keeps its own route file.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            SectionNavShell(navigationShell: navigationShell),
        navigatorContainerBuilder: SectionNavShell.branchContainer,
        branches: [
          for (final section in sections)
            StatefulShellBranch(
              initialLocation: section.homeLocation,
              routes: [
                ...section.routes,
                // Pages opened from the Settings hub join the Settings branch,
                // so opening one keeps the Settings tab selected.
                if (identical(section, settingsSection))
                  for (final other in sections) ...other.settingsRoutes,
              ],
            ),
        ],
      ),
    ],
  );
}

/// Bridges Riverpod provider changes (via ref.listen) to GoRouter's
/// Listenable-based refresh API.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
