import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/employee.dart';
import 'pages/employee_detail_page.dart';
import 'pages/employee_edit_page.dart';
import 'pages/employee_list_page.dart';
import 'pages/event_types_manager_page.dart';

part 'routes.g.dart';

@TypedGoRoute<EmployeesRoute>(path: '/employees')
class EmployeesRoute extends GoRouteData with $EmployeesRoute {
  const EmployeesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EmployeeListPage();
}

@TypedGoRoute<EmployeeNewRoute>(path: '/employees/new')
class EmployeeNewRoute extends GoRouteData with $EmployeeNewRoute {
  const EmployeeNewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EmployeeEditPage(existing: null);
}

@TypedGoRoute<EventTypesRoute>(path: '/employees/event-types')
class EventTypesRoute extends GoRouteData with $EventTypesRoute {
  const EventTypesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const EventTypesManagerPage();
}

@TypedGoRoute<EmployeeDetailRoute>(path: '/employees/:id')
class EmployeeDetailRoute extends GoRouteData with $EmployeeDetailRoute {
  const EmployeeDetailRoute(this.id);
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EmployeeDetailPage(employeeId: id);
}

@TypedGoRoute<EmployeeEditRoute>(path: '/employees/:id/edit')
class EmployeeEditRoute extends GoRouteData with $EmployeeEditRoute {
  const EmployeeEditRoute(this.id, {this.$extra});
  final String id;
  final Employee? $extra;

  // `extra` carries the already-fetched Employee so this doesn't need its
  // own async fetch. A deep link or reload arrives without extra — fall back
  // to the detail page (which fetches by id) instead of throwing.
  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      state.extra is Employee ? null : EmployeeDetailRoute(id).location;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      EmployeeEditPage(existing: $extra as Employee);
}
