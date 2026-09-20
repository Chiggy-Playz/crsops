import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_providers.dart';
import 'pages/employee_detail_page.dart';
import 'pages/employee_edit_page.dart';
import 'pages/employee_list_page.dart';
import 'pages/event_types_manager_page.dart';

List<RouteBase> employeeRoutes(Ref ref) => [
      GoRoute(path: '/employees', builder: (context, state) => const EmployeeListPage()),
      GoRoute(path: '/employees/new', builder: (context, state) => const EmployeeEditPage(existing: null)),
      GoRoute(
        path: '/employees/:id',
        builder: (context, state) => EmployeeDetailPage(employeeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/employees/event-types',
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isSuperadmin ? null : '/unauthorized';
        },
        builder: (context, state) => const EventTypesManagerPage(),
      ),
    ];
