// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$handlersRoute];

RouteBase get $handlersRoute => GoRouteData.$route(
  path: '/settings/challans/handlers',
  hasOverriddenOnExit: false,
  factory: $HandlersRoute._fromState,
);

mixin $HandlersRoute on GoRouteData {
  static HandlersRoute _fromState(GoRouterState state) => const HandlersRoute();

  @override
  String get location => GoRouteData.$location('/settings/challans/handlers');

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
