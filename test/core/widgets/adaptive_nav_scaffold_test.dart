import 'package:crs_ops/core/widgets/adaptive_nav_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestable(Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: AdaptiveNavScaffold(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(icon: Icon(Icons.people), label: 'Employees'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const Text('body'),
        ),
      ),
    );
  }

  testWidgets('shows a bottom NavigationBar below 600px', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(400, 800)));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('shows an icons-only rail from 600 to 1199px', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(1000, 600)));
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.labelType, NavigationRailLabelType.none);
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows a permanent navigation drawer from 1200px', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable(const Size(1300, 800)));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows just the page with fewer than two destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavScaffold(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const Text('body'),
        ),
      ),
    );
    expect(find.text('body'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });
}
