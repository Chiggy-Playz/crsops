// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$shiftDefaultsRoute, $statusTypesRoute];

RouteBase get $shiftDefaultsRoute => GoRouteData.$route(
  path: '/settings/attendance/shift-defaults',
  hasOverriddenOnExit: false,
  factory: $ShiftDefaultsRoute._fromState,
);

mixin $ShiftDefaultsRoute on GoRouteData {
  static ShiftDefaultsRoute _fromState(GoRouterState state) =>
      const ShiftDefaultsRoute();

  @override
  String get location =>
      GoRouteData.$location('/settings/attendance/shift-defaults');

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
  path: '/settings/attendance/status-types',
  hasOverriddenOnExit: false,
  factory: $StatusTypesRoute._fromState,
);

mixin $StatusTypesRoute on GoRouteData {
  static StatusTypesRoute _fromState(GoRouterState state) =>
      const StatusTypesRoute();

  @override
  String get location =>
      GoRouteData.$location('/settings/attendance/status-types');

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
