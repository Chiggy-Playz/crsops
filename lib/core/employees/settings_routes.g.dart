// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$eventTypesRoute];

RouteBase get $eventTypesRoute => GoRouteData.$route(
  path: '/settings/employees/event-types',
  hasOverriddenOnExit: false,
  factory: $EventTypesRoute._fromState,
);

mixin $EventTypesRoute on GoRouteData {
  static EventTypesRoute _fromState(GoRouterState state) =>
      const EventTypesRoute();

  @override
  String get location =>
      GoRouteData.$location('/settings/employees/event-types');

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
