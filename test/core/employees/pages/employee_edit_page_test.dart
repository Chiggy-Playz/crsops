import 'package:crs_ops/core/employees/pages/employee_edit_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_employee_event_repository.dart';
import '../fakes/fake_employee_repository.dart';

void main() {
  testWidgets('creating an employee saves it along with a join date', (
    tester,
  ) async {
    final employeeRepo = FakeEmployeeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [employeeRepositoryProvider.overrideWithValue(employeeRepo)],
        child: const MaterialApp(home: EmployeeEditPage(existing: null)),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('employee-name-field')),
      'Ramesh',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('employee-save-button')));
    await tester.pumpAndSettle();

    final saved = await employeeRepo.fetchAll();
    expect(saved, hasLength(1));
    expect(saved.first.name, 'Ramesh');
    expect(employeeRepo.joinedOnById, contains(saved.first.id));
  });

  testWidgets('saving without a name says so instead of saving', (
    tester,
  ) async {
    final employeeRepo = FakeEmployeeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(employeeRepo),
          employeeEventRepositoryProvider.overrideWithValue(
            FakeEmployeeEventRepository(),
          ),
        ],
        child: const MaterialApp(home: EmployeeEditPage(existing: null)),
      ),
    );

    await tester.tap(find.byKey(const Key('employee-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(await employeeRepo.fetchAll(), isEmpty);
  });
}
