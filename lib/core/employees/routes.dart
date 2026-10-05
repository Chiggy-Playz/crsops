import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/window_size.dart';
import '../router/dialog_page.dart';
import '../router/navigator_keys.dart';
import '../widgets/empty_state.dart';
import 'models/employee.dart';
import 'pages/employee_detail_page.dart';
import 'pages/employee_edit_page.dart';
import 'pages/employee_list_page.dart';
import 'pages/employees_split_layout.dart';

part 'routes.g.dart';

/// List + detail in one shell: two panes on wide windows (list left,
/// selected employee right), the usual list → detail pages on narrow ones.
///
/// new and :id/edit are nested (not top-level) because go_router only lets a
/// route under a shell target the root navigator if it's a sub-route — they
/// set $parentNavigatorKey to open above everything as form dialogs.
@TypedShellRoute<EmployeesShellRoute>(
  routes: [
    TypedGoRoute<EmployeesRoute>(
      path: '/employees',
      routes: [
        TypedGoRoute<EmployeeNewRoute>(path: 'new'),
        TypedGoRoute<EmployeeDetailRoute>(
          path: ':id',
          routes: [TypedGoRoute<EmployeeEditRoute>(path: 'edit')],
        ),
      ],
    ),
  ],
)
class EmployeesShellRoute extends ShellRouteData {
  const EmployeesShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      EmployeesSplitLayout(
        selectedId: state.pathParameters['id'],
        child: navigator,
      );
}

class EmployeesRoute extends GoRouteData with $EmployeesRoute {
  const EmployeesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Wide: the list is the left pane, so the right pane waits for a pick.
    if (context.isTwoPane) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Select an employee',
          message:
              'Pick someone from the list to see their details and history.',
        ),
      );
    }
    return const EmployeeListPage();
  }
}

class EmployeeNewRoute extends GoRouteData with $EmployeeNewRoute {
  const EmployeeNewRoute();

  // A focused task: pushed above the nav shell, as a form dialog.
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: const EmployeeEditPage(existing: null),
  );
}

class EmployeeDetailRoute extends GoRouteData with $EmployeeDetailRoute {
  const EmployeeDetailRoute(this.id);
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EmployeeDetailPage(employeeId: id);
}

class EmployeeEditRoute extends GoRouteData with $EmployeeEditRoute {
  const EmployeeEditRoute(this.id, {this.$extra});
  final String id;
  final Employee? $extra;

  // A focused task: pushed above the nav shell, as a form dialog.
  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  // `extra` carries the already-fetched Employee so this doesn't need its
  // own async fetch. A deep link or reload arrives without extra — fall back
  // to the detail page (which fetches by id) instead of throwing.
  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is Employee ? null : EmployeeDetailRoute(id).location;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => DialogPage(
    key: state.pageKey,
    child: EmployeeEditPage(existing: $extra as Employee),
  );
}
