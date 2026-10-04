// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $loadingRoute,
  $signInRoute,
  $unauthorizedRoute,
  $noModulesRoute,
];

RouteBase get $loadingRoute => GoRouteData.$route(
  path: '/loading',
  hasOverriddenOnExit: false,
  factory: $LoadingRoute._fromState,
);

mixin $LoadingRoute on GoRouteData {
  static LoadingRoute _fromState(GoRouterState state) => const LoadingRoute();

  @override
  String get location => GoRouteData.$location('/loading');

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

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/sign-in',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/sign-in');

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

RouteBase get $unauthorizedRoute => GoRouteData.$route(
  path: '/unauthorized',
  hasOverriddenOnExit: false,
  factory: $UnauthorizedRoute._fromState,
);

mixin $UnauthorizedRoute on GoRouteData {
  static UnauthorizedRoute _fromState(GoRouterState state) =>
      const UnauthorizedRoute();

  @override
  String get location => GoRouteData.$location('/unauthorized');

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

RouteBase get $noModulesRoute => GoRouteData.$route(
  path: '/no-modules',
  hasOverriddenOnExit: false,
  factory: $NoModulesRoute._fromState,
);

mixin $NoModulesRoute on GoRouteData {
  static NoModulesRoute _fromState(GoRouterState state) =>
      const NoModulesRoute();

  @override
  String get location => GoRouteData.$location('/no-modules');

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
