import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/connectivity/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value ?? true;
    final router = ref.watch(appRouterProvider);

    // One router, always mounted: the offline treatment is an overlay above
    // it, never a replacement MaterialApp — swapping the root on every
    // connectivity blip discarded dialogs, form input, and scroll state.
    return MaterialApp.router(
      routerConfig: router,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      builder: (context, child) => Stack(
        children: [
          child!,
          if (!isOnline)
            Positioned.fill(
              child: OfflineScreen(
                onRetry: () => ref.read(isOnlineProvider.notifier).retry(),
              ),
            ),
        ],
      ),
    );
  }
}
