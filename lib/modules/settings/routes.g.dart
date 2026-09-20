// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $settingsRoute,
  $allowListRoute,
  $rolesRoute,
  $moduleAccessRoute,
];

RouteBase get $settingsRoute => GoRouteData.$route(
  path: '/settings',
  hasOverriddenOnExit: false,
  factory: $SettingsRoute._fromState,
);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

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

RouteBase get $allowListRoute => GoRouteData.$route(
  path: '/settings/allow-list',
  hasOverriddenOnExit: false,
  factory: $AllowListRoute._fromState,
);

mixin $AllowListRoute on GoRouteData {
  static AllowListRoute _fromState(GoRouterState state) =>
      const AllowListRoute();

  @override
  String get location => GoRouteData.$location('/settings/allow-list');

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

RouteBase get $rolesRoute => GoRouteData.$route(
  path: '/settings/roles',
  hasOverriddenOnExit: false,
  factory: $RolesRoute._fromState,
);

mixin $RolesRoute on GoRouteData {
  static RolesRoute _fromState(GoRouterState state) => const RolesRoute();

  @override
  String get location => GoRouteData.$location('/settings/roles');

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

RouteBase get $moduleAccessRoute => GoRouteData.$route(
  path: '/settings/module-access',
  hasOverriddenOnExit: false,
  factory: $ModuleAccessRoute._fromState,
);

mixin $ModuleAccessRoute on GoRouteData {
  static ModuleAccessRoute _fromState(GoRouterState state) =>
      const ModuleAccessRoute();

  @override
  String get location => GoRouteData.$location('/settings/module-access');

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
