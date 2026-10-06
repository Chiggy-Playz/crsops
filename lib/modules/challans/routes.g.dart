// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$challansShellRoute];

RouteBase get $challansShellRoute => ShellRouteData.$route(
  factory: $ChallansShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/challans',
      hasOverriddenOnExit: false,
      factory: $ChallansRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'new',
          hasOverriddenOnExit: false,
          parentNavigatorKey: ChallanNewRoute.$parentNavigatorKey,
          factory: $ChallanNewRoute._fromState,
        ),
        GoRouteData.$route(
          path: 'search',
          hasOverriddenOnExit: false,
          factory: $ChallanSearchRoute._fromState,
        ),
        GoRouteData.$route(
          path: ':id',
          hasOverriddenOnExit: false,
          factory: $ChallanDetailRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'edit',
              hasOverriddenOnExit: false,
              parentNavigatorKey: ChallanEditRoute.$parentNavigatorKey,
              factory: $ChallanEditRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

extension $ChallansShellRouteExtension on ChallansShellRoute {
  static ChallansShellRoute _fromState(GoRouterState state) =>
      const ChallansShellRoute();
}

mixin $ChallansRoute on GoRouteData {
  static ChallansRoute _fromState(GoRouterState state) => const ChallansRoute();

  @override
  String get location => GoRouteData.$location('/challans');

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

mixin $ChallanNewRoute on GoRouteData {
  static ChallanNewRoute _fromState(GoRouterState state) => ChallanNewRoute(
    direction:
        _$convertMapValue(
          'direction',
          state.uri.queryParameters,
          _$ChallanDirectionEnumMap._$fromName,
        ) ??
        ChallanDirection.outward,
    clientId: state.uri.queryParameters['client-id'],
  );

  ChallanNewRoute get _self => this as ChallanNewRoute;

  @override
  String get location => GoRouteData.$location(
    '/challans/new',
    queryParams: {
      if (_self.direction != ChallanDirection.outward)
        'direction': _$ChallanDirectionEnumMap[_self.direction],
      if (_self.clientId != null) 'client-id': _self.clientId,
    },
  );

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

const _$ChallanDirectionEnumMap = {
  ChallanDirection.outward: 'outward',
  ChallanDirection.inward: 'inward',
};

mixin $ChallanSearchRoute on GoRouteData {
  static ChallanSearchRoute _fromState(GoRouterState state) =>
      const ChallanSearchRoute();

  @override
  String get location => GoRouteData.$location('/challans/search');

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

mixin $ChallanDetailRoute on GoRouteData {
  static ChallanDetailRoute _fromState(GoRouterState state) =>
      ChallanDetailRoute(state.pathParameters['id']!);

  ChallanDetailRoute get _self => this as ChallanDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/challans/${Uri.encodeComponent(_self.id)}');

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

mixin $ChallanEditRoute on GoRouteData {
  static ChallanEditRoute _fromState(GoRouterState state) => ChallanEditRoute(
    state.pathParameters['id']!,
    $extra: state.extra as Challan?,
  );

  ChallanEditRoute get _self => this as ChallanEditRoute;

  @override
  String get location =>
      GoRouteData.$location('/challans/${Uri.encodeComponent(_self.id)}/edit');

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

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}
