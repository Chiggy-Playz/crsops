import 'package:flutter/material.dart';

import '../layout/window_size.dart';

class AdaptiveNavScaffold extends StatelessWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A bar or rail with one destination is just noise (and NavigationBar
    // asserts on fewer than two) — show the page alone.
    if (destinations.length < 2) return child;

    // Which navigation, and how wide, comes from NavStyle — the same source
    // the panes use, so they always know how much room this takes.
    final style = context.navStyle;

    if (style == NavStyle.bottomBar) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      );
    }

    final theme = Theme.of(context);

    if (style == NavStyle.rail) {
      // Collapsed: icons only, the name as a tooltip — no tiny under-icon
      // captions. Same surface tone as the drawer.
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              minWidth: style.width,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              labelType: NavigationRailLabelType.none,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Tooltip(message: d.label, child: d.icon),
                    selectedIcon: Tooltip(
                      message: d.label,
                      child: d.selectedIcon ?? d.icon,
                    ),
                    label: Text(d.label),
                  ),
              ],
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // M3's standard navigation drawer, shown permanently: full-row
          // selection pill, normal-size labels, and its own surface tone so it
          // reads as navigation rather than a third content column.
          Theme(
            data: theme.copyWith(
              drawerTheme: theme.drawerTheme.copyWith(
                width: style.width,
                // Permanent, so square edges (the default rounded end
                // corners are for a drawer that slides over content).
                shape: const RoundedRectangleBorder(),
              ),
            ),
            child: NavigationDrawer(
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              elevation: 0,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 16, 16),
                  child: Text('CRS Ops', style: theme.textTheme.titleMedium),
                ),
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
