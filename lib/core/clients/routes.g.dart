// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$clientsShellRoute];

RouteBase get $clientsShellRoute => ShellRouteData.$route(
  factory: $ClientsShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/clients',
      hasOverriddenOnExit: false,
      factory: $ClientsRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'new',
          hasOverriddenOnExit: false,
          parentNavigatorKey: ClientNewRoute.$parentNavigatorKey,
          factory: $ClientNewRoute._fromState,
        ),
        GoRouteData.$route(
          path: ':id',
          hasOverriddenOnExit: false,
          factory: $ClientDetailRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'edit',
              hasOverriddenOnExit: false,
              parentNavigatorKey: ClientEditRoute.$parentNavigatorKey,
              factory: $ClientEditRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'addresses/new',
              hasOverriddenOnExit: false,
              parentNavigatorKey: AddressNewRoute.$parentNavigatorKey,
              factory: $AddressNewRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'addresses/:addressId/edit',
              hasOverriddenOnExit: false,
              parentNavigatorKey: AddressEditRoute.$parentNavigatorKey,
              factory: $AddressEditRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $ClientsShellRouteExtension on ClientsShellRoute {
  static ClientsShellRoute _fromState(GoRouterState state) =>
      const ClientsShellRoute();
}

mixin $ClientsRoute on GoRouteData {
  static ClientsRoute _fromState(GoRouterState state) => const ClientsRoute();

  @override
  String get location => GoRouteData.$location('/clients');

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

mixin $ClientNewRoute on GoRouteData {
  static ClientNewRoute _fromState(GoRouterState state) =>
      const ClientNewRoute();

  @override
  String get location => GoRouteData.$location('/clients/new');

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

mixin $ClientDetailRoute on GoRouteData {
  static ClientDetailRoute _fromState(GoRouterState state) =>
      ClientDetailRoute(state.pathParameters['id']!);

  ClientDetailRoute get _self => this as ClientDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/clients/${Uri.encodeComponent(_self.id)}');

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

mixin $ClientEditRoute on GoRouteData {
  static ClientEditRoute _fromState(GoRouterState state) => ClientEditRoute(
    state.pathParameters['id']!,
    $extra: state.extra as Client?,
  );

  ClientEditRoute get _self => this as ClientEditRoute;

  @override
  String get location =>
      GoRouteData.$location('/clients/${Uri.encodeComponent(_self.id)}/edit');

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

mixin $AddressNewRoute on GoRouteData {
  static AddressNewRoute _fromState(GoRouterState state) => AddressNewRoute(
    state.pathParameters['id']!,
    $extra: state.extra as Client?,
  );

  AddressNewRoute get _self => this as AddressNewRoute;

  @override
  String get location => GoRouteData.$location(
    '/clients/${Uri.encodeComponent(_self.id)}/addresses/new',
  );

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

mixin $AddressEditRoute on GoRouteData {
  static AddressEditRoute _fromState(GoRouterState state) => AddressEditRoute(
    state.pathParameters['id']!,
    state.pathParameters['addressId']!,
    $extra: state.extra as ClientAddress?,
  );

  AddressEditRoute get _self => this as AddressEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/clients/${Uri.encodeComponent(_self.id)}/addresses/${Uri.encodeComponent(_self.addressId)}/edit',
  );

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
