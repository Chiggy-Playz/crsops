import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/pages/loading_page.dart';
import '../auth/pages/sign_in_page.dart';
import '../auth/pages/unauthorized_page.dart';
import '../auth/providers/auth_providers.dart';
import '../widgets/adaptive_nav_scaffold.dart';
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
      GoRoute(
        path: '/',
        builder: (context, state) => const _PlaceholderHomeShell(),
      ),
    ],
  );
}

/// Real module branches (Calendar, Employees, Settings) replace this in Phases 2-3.
/// This proves the adaptive nav shell + sign-out flow end to end for Phase 1.
class _PlaceholderHomeShell extends ConsumerWidget {
  const _PlaceholderHomeShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    return AdaptiveNavScaffold(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${session?.email ?? ''}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bridges Riverpod provider changes (via ref.listen) to GoRouter's
/// Listenable-based refresh API.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
