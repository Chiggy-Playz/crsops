import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/pages/widgets/employee_multi_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _employees = [
  Employee(id: 'a', name: 'Amit', color: 0, createdAt: DateTime(2024)),
  Employee(id: 'b', name: 'Bhanu', color: 0, createdAt: DateTime(2024)),
  Employee(id: 'c', name: 'Chetan', color: 0, createdAt: DateTime(2024)),
];

/// Opens the picker and records what it resolved to.
Future<List<Set<String>?>> _open(
  WidgetTester tester, {
  Set<String> initialSelection = const {},
}) async {
  final results = <Set<String>?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await showEmployeeMultiPicker(
              context,
              employees: _employees,
              statusById: const {'a': 'inactive', 'b': 'active', 'c': 'active'},
              initialSelection: initialSelection,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('showEmployeeMultiPicker', () {
    testWidgets('lists active employees first, inactive under a header', (
      tester,
    ) async {
      await _open(tester);

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      // Amit sorts first alphabetically but is inactive.
      expect(top('Bhanu'), lessThan(top('Chetan')));
      expect(top('Chetan'), lessThan(top('Inactive')));
      expect(top('Inactive'), lessThan(top('Amit')));
    });

    testWidgets('applies the ticked employees', (tester) async {
      final results = await _open(tester);

      expect(find.text('Showing everyone'), findsOneWidget);
      await tester.tap(find.text('Bhanu'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(results, [
        {'b'},
      ]);
    });

    testWidgets('"All employees" clears the selection', (tester) async {
      final results = await _open(tester, initialSelection: {'b', 'c'});

      await tester.tap(find.text('All employees'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(results, [<String>{}]);
    });

    testWidgets('search filters the list', (tester) async {
      await _open(tester);

      await tester.enterText(find.byType(TextField), 'che');
      await tester.pumpAndSettle();

      expect(find.text('Chetan'), findsOneWidget);
      expect(find.text('Bhanu'), findsNothing);
    });
  });
}
