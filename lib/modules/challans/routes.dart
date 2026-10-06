import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/window_size.dart';
import '../../core/router/dialog_page.dart';
import '../../core/router/navigator_keys.dart';
import '../../core/widgets/empty_state.dart';
import 'models/challan.dart';
import 'models/challan_direction.dart';
import 'pages/challan_detail_page.dart';
import 'pages/challan_edit_page.dart';
import 'pages/challan_list_page.dart';
import 'pages/challan_pdf_page.dart';
import 'pages/challan_search_page.dart';
import 'pages/challans_split_layout.dart';

part 'routes.g.dart';

/// Same shape as the clients routes: list + detail as two panes on wide
/// windows, list → detail pages on narrow ones; the form opens above
/// everything as a dialog.
@TypedShellRoute<ChallansShellRoute>(
  routes: [
    TypedGoRoute<ChallansRoute>(
      path: '/challans',
      routes: [
        TypedGoRoute<ChallanNewRoute>(path: 'new'),
        // Before ':id', so "search" isn't read as a challan id.
        TypedGoRoute<ChallanSearchRoute>(path: 'search'),
        TypedGoRoute<ChallanDetailRoute>(
          path: ':id',
          routes: [
            TypedGoRoute<ChallanEditRoute>(path: 'edit'),
            TypedGoRoute<ChallanPdfRoute>(path: 'pdf'),
          ],
        ),
      ],
    ),
  ],
)
class ChallansShellRoute extends ShellRouteData {
  const ChallansShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      ChallansSplitLayout(
        selectedId: state.pathParameters['id'],
        child: navigator,
      );
}

class ChallansRoute extends GoRouteData with $ChallansRoute {
  const ChallansRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Wide: the list is the left pane, so the right pane waits for a pick.
    if (context.isTwoPane) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Select a challan',
          message: 'Pick a challan from the list to see it.',
        ),
      );
    }
    return const ChallanListPage();
  }
}

/// `?direction=inward` for an inward challan; `&client-id=…` when started
/// from a client's page.
class ChallanNewRoute extends GoRouteData with $ChallanNewRoute {
  const ChallanNewRoute({
    this.direction = ChallanDirection.outward,
    this.clientId,
  });

  final ChallanDirection direction;
  final String? clientId;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: ChallanEditPage(
      existing: null,
      direction: direction,
      clientId: clientId,
    ),
  );
}

/// Right pane on wide windows, its own page on narrow ones.
class ChallanSearchRoute extends GoRouteData with $ChallanSearchRoute {
  const ChallanSearchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ChallanSearchPage();
}

class ChallanDetailRoute extends GoRouteData with $ChallanDetailRoute {
  const ChallanDetailRoute(this.id);
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ChallanDetailPage(challanId: id);
}

/// Gets the already-fetched challan (with its items) through `extra`. A deep
/// link or reload arrives without it and falls back to the challan's page.
class ChallanEditRoute extends GoRouteData with $ChallanEditRoute {
  const ChallanEditRoute(this.id, {this.$extra});
  final String id;
  final Challan? $extra;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is Challan ? null : ChallanDetailRoute(id).location;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: ChallanEditPage(existing: $extra as Challan),
  );
}

/// The PDF preview, full screen above everything. Loads the challan itself,
/// so it works from a link too.
class ChallanPdfRoute extends GoRouteData with $ChallanPdfRoute {
  const ChallanPdfRoute(this.id);
  final String id;

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage(
        key: state.pageKey,
        fullscreenDialog: true,
        child: ChallanPdfPage(challanId: id),
      );
}
