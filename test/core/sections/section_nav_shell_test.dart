import 'package:crs_ops/app_router.dart';
import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/providers/auth_providers.dart';
import 'package:crs_ops/core/sections/app_section.dart';
import 'package:crs_ops/core/sections/app_sections_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AppSection _section(
  String name, {
  required SessionCheck canAccess,
  bool isLandingCandidate = true,
}) => AppSection(
  label: name,
  icon: Icons.circle_outlined,
  selectedIcon: Icons.circle,
  canAccess: canAccess,
  pathPrefix: '/$name',
  homeLocation: '/$name',
  isLandingCandidate: isLandingCandidate,
  routes: [
    GoRoute(
      path: '/$name',
      builder: (context, state) => Scaffold(body: Text('page $name')),
    ),
  ],
);

// Branch order: a, b, s. Visibility differs per user, so bar positions and
// branch indexes diverge — exactly what the shell has to translate.
final _sections = [
  _section('a', canAccess: (s) => s.hasModuleAccess('a')),
  _section('b', canAccess: (s) => s.isAdminOrAbove),
  _section('s', canAccess: (_) => true, isLandingCandidate: false),
];

AppSession _session(AppRole role, {Set<String> modules = const {}}) =>
    AppSession(userId: 'u', email: 'e', role: role, moduleAccess: modules);

Future<GoRouter> _pumpApp(WidgetTester tester, AppSession session) async {
  final container = ProviderContainer(
    overrides: [
      appSectionsProvider.overrideWithValue(_sections),
      sessionProvider.overrideWithValue(AsyncData(session)),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

List<String> _barLabels(WidgetTester tester) => tester
    .widget<NavigationBar>(find.byType(NavigationBar))
    .destinations
    .map((d) => (d as NavigationDestination).label)
    .toList();

int _barSelected(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(400, 800); // compact → bottom bar
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  });

  testWidgets('admin sees every section, landing on the first', (tester) async {
    await _pumpApp(tester, _session(AppRole.admin));

    expect(_barLabels(tester), ['a', 'b', 's']);
    expect(find.text('page a'), findsOneWidget);
    expect(_barSelected(tester), 0);
  });

  testWidgets('the bar only shows sections the user can access', (
    tester,
  ) async {
    await _pumpApp(tester, _session(AppRole.employee, modules: {'a'}));

    expect(_barLabels(tester), ['a', 's']);
  });

  testWidgets('bar positions map to the right branches', (tester) async {
    // 's' is branch 2 but bar position 1 for this user.
    await _pumpApp(tester, _session(AppRole.employee, modules: {'a'}));

    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('s')),
    );
    await tester.pumpAndSettle();

    expect(find.text('page s'), findsOneWidget);
    expect(_barSelected(tester), 1);
  });

  testWidgets('no bar when only one section is visible', (tester) async {
    final router = await _pumpApp(tester, _session(AppRole.employee));

    // Only 's' is visible, and it isn't a landing spot.
    expect(find.text('No modules yet'), findsOneWidget);

    router.go('/s');
    await tester.pumpAndSettle();

    expect(find.text('page s'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
