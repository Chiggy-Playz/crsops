// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$employeesShellRoute];

RouteBase get $employeesShellRoute => ShellRouteData.$route(
  factory: $EmployeesShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/employees',
      hasOverriddenOnExit: false,
      factory: $EmployeesRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'new',
          hasOverriddenOnExit: false,
          parentNavigatorKey: EmployeeNewRoute.$parentNavigatorKey,
          factory: $EmployeeNewRoute._fromState,
        ),
        GoRouteData.$route(
          path: ':id',
          hasOverriddenOnExit: false,
          factory: $EmployeeDetailRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'edit',
              hasOverriddenOnExit: false,
              parentNavigatorKey: EmployeeEditRoute.$parentNavigatorKey,
              factory: $EmployeeEditRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $EmployeesShellRouteExtension on EmployeesShellRoute {
  static EmployeesShellRoute _fromState(GoRouterState state) =>
      const EmployeesShellRoute();
}

mixin $EmployeesRoute on GoRouteData {
  static EmployeesRoute _fromState(GoRouterState state) =>
      const EmployeesRoute();

  @override
  String get location => GoRouteData.$location('/employees');

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

mixin $EmployeeNewRoute on GoRouteData {
  static EmployeeNewRoute _fromState(GoRouterState state) =>
      const EmployeeNewRoute();

  @override
  String get location => GoRouteData.$location('/employees/new');

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

mixin $EmployeeDetailRoute on GoRouteData {
  static EmployeeDetailRoute _fromState(GoRouterState state) =>
      EmployeeDetailRoute(state.pathParameters['id']!);

  EmployeeDetailRoute get _self => this as EmployeeDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/employees/${Uri.encodeComponent(_self.id)}');

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

mixin $EmployeeEditRoute on GoRouteData {
  static EmployeeEditRoute _fromState(GoRouterState state) => EmployeeEditRoute(
    state.pathParameters['id']!,
    $extra: state.extra as Employee?,
  );

  EmployeeEditRoute get _self => this as EmployeeEditRoute;

  @override
  String get location =>
      GoRouteData.$location('/employees/${Uri.encodeComponent(_self.id)}/edit');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}
