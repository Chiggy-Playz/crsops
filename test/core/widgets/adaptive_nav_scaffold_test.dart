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
            NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
            NavigationDestination(icon: Icon(Icons.people), label: 'Employees'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const Text('body'),
        ),
      ),
    );
  }

  testWidgets('shows a bottom NavigationBar below the compact breakpoint', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(400, 800)));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows a NavigationRail at/above the compact breakpoint', (tester) async {
    await tester.pumpWidget(buildTestable(const Size(800, 600)));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
