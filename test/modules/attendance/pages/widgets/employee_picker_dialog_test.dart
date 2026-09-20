import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/modules/attendance/pages/widgets/employee_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showEmployeePicker', () {
    testWidgets('returns the checked selection on Done', (tester) async {
      Set<String>? result;
      final employees = [
        Employee(
          id: '1',
          name: 'Ramesh',
          color: 0xFF4CAF50,
          createdAt: DateTime(2024),
        ),
        Employee(
          id: '2',
          name: 'Suresh',
          color: 0xFF2196F3,
          createdAt: DateTime(2024),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showEmployeePicker(
                  context,
                  employees: employees,
                  initialSelection: const {},
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suresh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result, {'2'});
    });

    testWidgets('starts with the initial selection checked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEmployeePicker(
                context,
                employees: [
                  Employee(
                    id: '1',
                    name: 'Ramesh',
                    color: 0xFF4CAF50,
                    createdAt: DateTime(2024),
                  ),
                ],
                initialSelection: const {'1'},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 'All employees' unchecked means a specific selection is active.
      final allTile = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'All employees'),
      );
      expect(allTile.value, isFalse);
    });
  });
}
