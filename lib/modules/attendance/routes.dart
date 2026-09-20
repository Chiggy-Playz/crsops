import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/providers/auth_providers.dart';
import '../../core/router/route_names.dart';
import 'pages/attendance_day_page.dart';
import 'pages/calendar_page.dart';
import 'pages/report_page.dart';
import 'pages/shift_defaults_manager_page.dart';
import 'pages/status_types_manager_page.dart';

List<RouteBase> attendanceRoutes(Ref ref) => [
      GoRoute(
        path: '/',
        name: RouteNames.calendar,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.hasModuleAccess('attendance') ? null : '/unauthorized';
        },
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/attendance/:date',
        name: RouteNames.attendanceDay,
        builder: (context, state) =>
            AttendanceDayPage(date: DateTime.parse(state.pathParameters['date']!)),
      ),
      GoRoute(
        path: '/reports',
        name: RouteNames.reports,
        builder: (context, state) => const ReportPage(),
      ),
      GoRoute(
        path: '/attendance/shift-defaults',
        name: RouteNames.shiftDefaults,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const ShiftDefaultsManagerPage(),
      ),
      GoRoute(
        path: '/attendance/status-types',
        name: RouteNames.statusTypes,
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          return session != null && session.isAdminOrAbove ? null : '/unauthorized';
        },
        builder: (context, state) => const StatusTypesManagerPage(),
      ),
    ];
