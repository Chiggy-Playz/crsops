// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $employeesRoute,
  $employeeNewRoute,
  $eventTypesRoute,
  $employeeDetailRoute,
  $employeeEditRoute,
];

RouteBase get $employeesRoute => GoRouteData.$route(
  path: '/employees',
  hasOverriddenOnExit: false,
  factory: $EmployeesRoute._fromState,
);

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

RouteBase get $employeeNewRoute => GoRouteData.$route(
  path: '/employees/new',
  hasOverriddenOnExit: false,
  factory: $EmployeeNewRoute._fromState,
);

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

RouteBase get $eventTypesRoute => GoRouteData.$route(
  path: '/employees/event-types',
  hasOverriddenOnExit: false,
  factory: $EventTypesRoute._fromState,
);

mixin $EventTypesRoute on GoRouteData {
  static EventTypesRoute _fromState(GoRouterState state) =>
      const EventTypesRoute();

  @override
  String get location => GoRouteData.$location('/employees/event-types');

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

RouteBase get $employeeDetailRoute => GoRouteData.$route(
  path: '/employees/:id',
  hasOverriddenOnExit: false,
  factory: $EmployeeDetailRoute._fromState,
);

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

RouteBase get $employeeEditRoute => GoRouteData.$route(
  path: '/employees/:id/edit',
  hasOverriddenOnExit: false,
  factory: $EmployeeEditRoute._fromState,
);

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
