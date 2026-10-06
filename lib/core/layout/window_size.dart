import 'package:flutter/widgets.dart';

/// M3 window size classes (m3.material.io → Foundations → Layout).
enum WindowSize {
  compact, // < 600: phones
  medium, // 600–839: small tablets, portrait foldables
  expanded, // 840–1199
  large; // ≥ 1200: room for wider dashboards

  static WindowSize of(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    if (width < 1200) return expanded;
    return large;
  }
}

/// Which app navigation shows at a window width — the one source of truth
/// for both the navigation (AdaptiveNavScaffold) and the panes, so the panes
/// always know how much room the navigation takes.
enum NavStyle {
  bottomBar, // phones: takes no width
  rail, // tablets, half-screen windows: icons only (names as tooltips)
  drawer; // desktop: icons + labels

  static NavStyle of(double windowWidth) {
    if (windowWidth < 600) return bottomBar;
    if (windowWidth < 1200) return rail;
    return drawer;
  }

  /// Horizontal space this navigation takes from the content.
  double get width {
    switch (this) {
      case NavStyle.bottomBar:
        return 0;
      case NavStyle.rail:
        return 80;
      case NavStyle.drawer:
        return 240;
    }
  }
}

/// Content width needed for two panes (a ~480 px list/calendar pane plus a
/// usable right pane).
const double twoPaneMinContentWidth = 840;

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => WindowSize.of(MediaQuery.sizeOf(this).width);

  NavStyle get navStyle => NavStyle.of(MediaQuery.sizeOf(this).width);

  /// The width left for page content once the app navigation is drawn.
  double get contentWidth => MediaQuery.sizeOf(this).width - navStyle.width;

  /// Room for two panes *after* the navigation. Every two-pane decision
  /// (layouts, back arrows, dialog vs sheet, go vs push) reads this, so they
  /// can't disagree.
  bool get isTwoPane => contentWidth >= twoPaneMinContentWidth;
}

/// [WindowSizeContext.isTwoPane] for route redirects, read from the window
/// itself rather than MediaQuery. A redirect that reads MediaQuery makes the
/// router depend on the window size, and go_router then replays the current
/// navigation on every resize: pushed pages get pushed again, and a form's
/// "Discard changes?" check fires as if it were being left.
bool isTwoPaneWindow(BuildContext context) {
  final view = View.of(context);
  final width = view.physicalSize.width / view.devicePixelRatio;
  return width - NavStyle.of(width).width >= twoPaneMinContentWidth;
}
