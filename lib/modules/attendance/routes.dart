import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/attendance_day_page.dart';
import 'pages/calendar_page.dart';
import 'pages/report_page.dart';

part 'routes.g.dart';

@TypedGoRoute<CalendarRoute>(path: '/attendance/calendar')
class CalendarRoute extends GoRouteData with $CalendarRoute {
  const CalendarRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CalendarPage();
}

@TypedGoRoute<ReportsRoute>(path: '/attendance/reports')
class ReportsRoute extends GoRouteData with $ReportsRoute {
  const ReportsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ReportPage();
}

@TypedGoRoute<AttendanceDayRoute>(path: '/attendance/:date')
class AttendanceDayRoute extends GoRouteData with $AttendanceDayRoute {
  // Kept a String (not DateTime) on purpose: codegen field decoding would
  // throw on a malformed date before redirect runs, bypassing the guard
  // below. Raw-string redirect first, parse in build.
  const AttendanceDayRoute(this.date);
  final String date;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      DateTime.tryParse(state.pathParameters['date'] ?? '') == null
      ? const CalendarRoute().location
      : null;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AttendanceDayPage(date: DateTime.parse(date));
}
