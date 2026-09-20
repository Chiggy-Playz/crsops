import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import '../router/route_names.dart';
import 'models/employee.dart';
import 'pages/employee_detail_page.dart';
import 'pages/employee_edit_page.dart';
import 'pages/employee_list_page.dart';
import 'pages/event_types_manager_page.dart';

List<RouteBase> employeeRoutes(Ref ref) => [
  GoRoute(
    path: '/employees',
    name: RouteNames.employees,
    builder: (context, state) => const EmployeeListPage(),
  ),
  GoRoute(
    path: '/employees/new',
    name: RouteNames.employeeNew,
    builder: (context, state) => const EmployeeEditPage(existing: null),
  ),
  GoRoute(
    path: '/employees/event-types',
    name: RouteNames.eventTypes,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      return session != null && session.isSuperadmin ? null : '/unauthorized';
    },
    builder: (context, state) => const EventTypesManagerPage(),
  ),
  GoRoute(
    path: '/employees/:id',
    name: RouteNames.employeeDetail,
    builder: (context, state) =>
        EmployeeDetailPage(employeeId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/employees/:id/edit',
    name: RouteNames.employeeEdit,
    // `extra` carries the already-fetched Employee so this doesn't need
    // its own async fetch — the detail page that navigates here already
    // has the full object via employeeProvider. A deep link or reload
    // arrives without extra, so guard the cast and fall back to the
    // detail page (which fetches by id) instead of throwing.
    redirect: (context, state) => state.extra is Employee
        ? null
        : '/employees/${state.pathParameters['id']}',
    builder: (context, state) =>
        EmployeeEditPage(existing: state.extra as Employee),
  ),
];
