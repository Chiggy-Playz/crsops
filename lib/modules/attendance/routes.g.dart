// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $calendarRoute,
  $reportsRoute,
  $shiftDefaultsRoute,
  $statusTypesRoute,
  $attendanceDayRoute,
];

RouteBase get $calendarRoute => GoRouteData.$route(
  path: '/attendance/calendar',
  hasOverriddenOnExit: false,
  factory: $CalendarRoute._fromState,
);

mixin $CalendarRoute on GoRouteData {
  static CalendarRoute _fromState(GoRouterState state) => const CalendarRoute();

  @override
  String get location => GoRouteData.$location('/attendance/calendar');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $reportsRoute => GoRouteData.$route(
  path: '/attendance/reports',
  hasOverriddenOnExit: false,
  factory: $ReportsRoute._fromState,
);

mixin $ReportsRoute on GoRouteData {
  static ReportsRoute _fromState(GoRouterState state) => const ReportsRoute();

  @override
  String get location => GoRouteData.$location('/attendance/reports');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $shiftDefaultsRoute => GoRouteData.$route(
  path: '/attendance/shift-defaults',
  hasOverriddenOnExit: false,
  factory: $ShiftDefaultsRoute._fromState,
);

mixin $ShiftDefaultsRoute on GoRouteData {
  static ShiftDefaultsRoute _fromState(GoRouterState state) =>
      const ShiftDefaultsRoute();

  @override
  String get location => GoRouteData.$location('/attendance/shift-defaults');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $statusTypesRoute => GoRouteData.$route(
  path: '/attendance/status-types',
  hasOverriddenOnExit: false,
  factory: $StatusTypesRoute._fromState,
);

mixin $StatusTypesRoute on GoRouteData {
  static StatusTypesRoute _fromState(GoRouterState state) =>
      const StatusTypesRoute();

  @override
  String get location => GoRouteData.$location('/attendance/status-types');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $attendanceDayRoute => GoRouteData.$route(
  path: '/attendance/:date',
  hasOverriddenOnExit: false,
  factory: $AttendanceDayRoute._fromState,
);

mixin $AttendanceDayRoute on GoRouteData {
  static AttendanceDayRoute _fromState(GoRouterState state) =>
      AttendanceDayRoute(state.pathParameters['date']!);

  AttendanceDayRoute get _self => this as AttendanceDayRoute;

  @override
  String get location =>
      GoRouteData.$location('/attendance/${Uri.encodeComponent(_self.date)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
