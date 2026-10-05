import 'package:flutter/widgets.dart';

/// M3 window size classes (m3.material.io → Foundations → Layout).
enum WindowSize {
  compact, // < 600: phones
  medium, // 600–839: small tablets, portrait foldables
  expanded, // 840–1199: two panes
  large; // ≥ 1200: room for wider dashboards

  static WindowSize of(double width) {
    if (width < 600) return compact;
    if (width < 840) return medium;
    if (width < 1200) return expanded;
    return large;
  }
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => WindowSize.of(MediaQuery.sizeOf(this).width);

  /// Wide enough for two panes (expanded or large).
  bool get isTwoPane => windowSize.index >= WindowSize.expanded.index;
}
