import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/pages/employee_list_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_repository.dart';

Widget _wrap(Widget child, {required FakeEmployeeRepository repo}) => ProviderScope(
      overrides: [employeeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('shows an empty state when there are no employees', (tester) async {
    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('No employees yet'), findsOneWidget);
  });

  testWidgets('lists employees with their name and color swatch', (tester) async {
    final repo = FakeEmployeeRepository(seed: [
      Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
      Employee(id: '2', name: 'Suresh', color: 0xFF2196F3, createdAt: DateTime(2024, 1, 1)),
    ]);

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsOneWidget);
  });

  testWidgets('search field filters the list by name', (tester) async {
    final repo = FakeEmployeeRepository(seed: [
      Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
      Employee(id: '2', name: 'Suresh', color: 0xFF2196F3, createdAt: DateTime(2024, 1, 1)),
    ]);

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ram');
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsNothing);
  });

  testWidgets('has a FAB to add an employee', (tester) async {
    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: FakeEmployeeRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('hides inactive employees by default, toggle reveals them', (tester) async {
    final repo = FakeEmployeeRepository(
      seed: [
        Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
        Employee(id: '2', name: 'Suresh', color: 0xFF2196F3, createdAt: DateTime(2024, 1, 1)),
      ],
      statusById: {'1': 'active', '2': 'inactive'},
    );

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsNothing);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsOneWidget);
    expect(find.text('Suresh'), findsOneWidget);
  });

  testWidgets('shown inactive employees sit below an Inactive header', (tester) async {
    final repo = FakeEmployeeRepository(
      seed: [
        Employee(id: '1', name: 'Amit', color: 0, createdAt: DateTime(2024, 1, 1)),
        Employee(id: '2', name: 'Bhanu', color: 0, createdAt: DateTime(2024, 1, 1)),
        Employee(id: '3', name: 'Chetan', color: 0, createdAt: DateTime(2024, 1, 1)),
      ],
      statusById: {'1': 'inactive', '2': 'active', '3': 'active'},
    );

    await tester.pumpWidget(_wrap(const EmployeeListPage(), repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    // Amit sorts first alphabetically but is inactive, so goes last.
    expect(top('Bhanu'), lessThan(top('Chetan')));
    expect(top('Chetan'), lessThan(top('Inactive')));
    expect(top('Inactive'), lessThan(top('Amit')));
  });
}
