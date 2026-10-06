import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'window_size.dart';

/// M3 list-detail / supporting-pane layout for wide windows: a fixed-width
/// [pane] on the left, the routed [child] on the right. Below the two-pane
/// breakpoint it steps aside and shows only [child], so phones keep their
/// single-page navigation.
class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.pane,
    required this.child,
    this.paneWidth = 360,
  });

  final Widget pane;
  final Widget child;
  final double paneWidth;

  @override
  Widget build(BuildContext context) {
    if (!context.isTwoPane) return child;

    return Row(
      children: [
        SizedBox(width: paneWidth, child: pane),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}

/// Leading-widget rules for a page that is the right pane on wide windows and
/// a full page on narrow ones:
/// - two panes: ✕, which closes the pane back to [parentLocation] (the list
///   stays on the left), or nothing when [closable] is false;
/// - single pane with something to pop: the normal back arrow;
/// - single pane with nothing to pop (deep link, or resized from wide):
///   a back arrow that goes to [parentLocation].
({Widget? leading, bool implyLeading}) paneLeading(
  BuildContext context, {
  required String parentLocation,
  bool closable = true,
}) {
  if (context.isTwoPane) {
    if (!closable) return (leading: null, implyLeading: false);
    return (
      leading: CloseButton(onPressed: () => context.go(parentLocation)),
      implyLeading: false,
    );
  }
  if (Navigator.of(context).canPop()) {
    return (leading: null, implyLeading: true);
  }
  return (
    leading: BackButton(onPressed: () => context.go(parentLocation)),
    implyLeading: false,
  );
}

/// Opens [location] the right way for the layout: on wide windows it replaces
/// the right pane (`go`); on narrow ones it stacks a page (`push`) so back
/// returns to the list.
void openInPane(BuildContext context, String location) {
  if (context.isTwoPane) {
    context.go(location);
  } else {
    context.push(location);
  }
}

/// Caps content width and centres it, so single-pane pages don't stretch
/// across a wide window.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({super.key, required this.child, this.maxWidth = 840});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// App bar for a page that is the right pane on wide windows and a full page
/// on narrow ones — applies [paneLeading]'s back-arrow rules.
class PaneAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PaneAppBar({
    super.key,
    required this.title,
    required this.parentLocation,
    this.actions,
  });

  final String title;
  final String parentLocation;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);

  @override
  Widget build(BuildContext context) {
    final leading = paneLeading(context, parentLocation: parentLocation);
    return AppBar(
      leading: leading.leading,
      automaticallyImplyLeading: leading.implyLeading,
      title: Text(title),
      actions: actions,
    );
  }
}
