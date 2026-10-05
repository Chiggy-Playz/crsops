import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/window_size.dart';
import '../../core/router/dialog_page.dart';
import '../../core/utils/date_key.dart';
import '../../core/widgets/empty_state.dart';
import 'pages/attendance_day_page.dart';
import 'pages/attendance_split_layout.dart';
import 'pages/calendar_page.dart';
import 'pages/report_page.dart';

part 'routes.g.dart';

// Declared before the shell: '/attendance/reports' would otherwise match the
// shell's '/attendance/:date' as a "date" called "reports".
@TypedGoRoute<ReportsRoute>(
  path: '/attendance/reports',
  routes: [TypedGoRoute<ReportDayRoute>(path: ':date')],
)
class ReportsRoute extends GoRouteData with $ReportsRoute {
  const ReportsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ReportPage();
}

/// A day opened from the Reports calendar, on top of Reports (so back returns
/// to it with filters intact) — a centred dialog on wide windows, a page on
/// phones. A child of Reports, outside the attendance shell, so it never
/// stacks a second shell.
class ReportDayRoute extends GoRouteData with $ReportDayRoute {
  // String for the same reason as AttendanceDayRoute: validate, then parse.
  const ReportDayRoute(this.date);
  final String date;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      _redirectIfBadDate(state, fallback: const ReportsRoute().location);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final page = AttendanceDayPage(
      date: DateTime.parse(date),
      openedFromReports: true,
    );
    if (!context.isTwoPane) {
      return MaterialPage(key: state.pageKey, child: page);
    }
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return DialogPage(
      key: state.pageKey,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 720, height: height, child: page),
      ),
    );
  }
}

/// Calendar + day in one shell: two panes on wide windows (calendar left,
/// day right), the usual calendar → day pages on narrow ones.
@TypedShellRoute<AttendanceShellRoute>(
  routes: [
    TypedGoRoute<CalendarRoute>(path: '/attendance/calendar'),
    TypedGoRoute<AttendanceDayRoute>(path: '/attendance/:date'),
  ],
)
class AttendanceShellRoute extends ShellRouteData {
  const AttendanceShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AttendanceSplitLayout(
        selectedDate: DateTime.tryParse(state.pathParameters['date'] ?? ''),
        child: navigator,
      );
}

class CalendarRoute extends GoRouteData with $CalendarRoute {
  const CalendarRoute();

  // Wide windows open on today's day pane next to the calendar, so the daily
  // marking needs no clicks.
  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      context.isTwoPane
      ? AttendanceDayRoute(dateOnly(DateTime.now())).location
      : null;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    // Only reachable on wide windows by resizing while on the calendar page:
    // the calendar is already the left pane, so don't show it twice.
    if (context.isTwoPane) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.event_outlined,
          title: 'Pick a date',
          message: 'Choose a day in the calendar to see and mark attendance.',
        ),
      );
    }
    return const CalendarPage();
  }
}

class AttendanceDayRoute extends GoRouteData with $AttendanceDayRoute {
  // Kept a String (not DateTime) on purpose: codegen field decoding would
  // throw on a malformed date before redirect runs, bypassing the guard
  // below. Raw-string redirect first, parse in build.
  const AttendanceDayRoute(this.date);
  final String date;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      _redirectIfBadDate(state, fallback: const CalendarRoute().location);

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AttendanceDayPage(date: DateTime.parse(date));
}

/// Shared by the day routes: a `:date` that isn't a date (typo, old link)
/// goes to [fallback] instead of crashing in build.
String? _redirectIfBadDate(GoRouterState state, {required String fallback}) =>
    DateTime.tryParse(state.pathParameters['date'] ?? '') == null
    ? fallback
    : null;
