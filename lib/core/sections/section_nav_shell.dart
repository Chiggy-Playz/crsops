import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import '../widgets/adaptive_nav_scaffold.dart';
import 'app_sections_provider.dart';

/// Wraps the StatefulShellRoute: one branch per section (always all of them,
/// in `appSectionsProvider` order), but the bar only shows the sections this
/// user can access — so bar positions and branch indexes differ, and this
/// widget translates between them.
class SectionNavShell extends ConsumerWidget {
  const SectionNavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Like `StatefulShellRoute.indexedStack`'s container, but heroes are off
  /// in hidden branches. Every visited branch stays alive, so without this a
  /// page pushed above the shell (new employee) finds one default-tagged FAB
  /// per live branch and Flutter asserts on the duplicate hero tags.
  static Widget branchContainer(
    BuildContext context,
    StatefulNavigationShell navigationShell,
    List<Widget> children,
  ) {
    final current = navigationShell.currentIndex;
    return IndexedStack(
      index: current,
      children: [
        for (var i = 0; i < children.length; i++)
          HeroMode(
            enabled: i == current,
            child: TickerMode(enabled: i == current, child: children[i]),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(appSectionsProvider);
    final session = ref.watch(sessionProvider).value;

    final visibleBranches = [
      for (var i = 0; i < sections.length; i++)
        if (session != null && sections[i].canAccess(session)) i,
    ];
    final selected = visibleBranches.indexOf(navigationShell.currentIndex);

    // Android's predictive back decides before the app hears about it
    // whether back closes something in the app or leaves it, going by what
    // the navigators last reported. Each section keeps its own pages, but a
    // switch only makes the outer navigator report ("nothing to go back
    // to"), so back on a form left open in a section would exit the app.
    // Report what the router can really go back from, after the switch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      NavigationNotification(
        canHandlePop: GoRouter.of(context).canPop(),
      ).dispatch(context);
    });

    return AdaptiveNavScaffold(
      destinations: [
        for (final i in visibleBranches)
          NavigationDestination(
            icon: Icon(sections[i].icon),
            selectedIcon: Icon(sections[i].selectedIcon),
            label: sections[i].label,
          ),
      ],
      selectedIndex: selected < 0 ? 0 : selected,
      onDestinationSelected: (position) {
        final branch = visibleBranches[position];
        // Re-tapping the current tab pops it back to its home screen.
        navigationShell.goBranch(
          branch,
          initialLocation: branch == navigationShell.currentIndex,
        );
      },
      child: navigationShell,
    );
  }
}
