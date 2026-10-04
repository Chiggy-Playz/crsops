import 'package:crs_ops/core/widgets/creatable_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pump(WidgetTester tester) async {
  final values = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CreatableDropdownField(
            fieldKey: const Key('field'),
            options: const ['salary_payment', 'advance'],
            label: 'Category',
            onChanged: values.add,
          ),
        ),
      ),
    ),
  );
  return values;
}

Finder _menuItem(String text) =>
    find.descendant(of: find.byType(MenuItemButton), matching: find.text(text));

void main() {
  group('CreatableDropdownField', () {
    testWidgets('typing filters the existing options', (tester) async {
      await _pump(tester);

      await tester.enterText(find.byKey(const Key('field')), 'sal');
      await tester.pumpAndSettle();

      expect(_menuItem('Salary Payment'), findsOneWidget);
      expect(_menuItem('Advance'), findsNothing);
    });

    testWidgets('text matching nothing offers an explicit Add row', (
      tester,
    ) async {
      final values = await _pump(tester);

      await tester.enterText(find.byKey(const Key('field')), 'Bonus');
      await tester.pumpAndSettle();

      expect(_menuItem("Add 'Bonus'"), findsOneWidget);
      expect(values.last, 'Bonus');
    });

    testWidgets('text naming an option reports the stored value', (
      tester,
    ) async {
      final values = await _pump(tester);

      await tester.enterText(find.byKey(const Key('field')), 'salary payment');
      await tester.pumpAndSettle();

      expect(values.last, 'salary_payment');
      expect(find.textContaining('Add '), findsNothing);
    });
  });
}
