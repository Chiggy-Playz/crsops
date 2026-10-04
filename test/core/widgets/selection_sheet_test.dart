import 'package:crs_ops/core/widgets/selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = [
  SelectionOption(value: 'a', label: 'Alpha', icon: Icons.looks_one),
  SelectionOption(value: 'b', label: 'Beta', icon: Icons.looks_two),
  SelectionOption(value: 'c', label: 'Gamma'),
];

/// Pumps a button that opens the sheet and records what it resolved to.
Future<List<String?>> _pumpOpener(WidgetTester tester) async {
  final results = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await showSelectionSheet(
              context: context,
              title: 'Pick one',
              options: _options,
              selected: 'a',
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
  group('showSelectionSheet', () {
    testWidgets('shows the title and every option, marking the current one', (
      tester,
    ) async {
      await _pumpOpener(tester);

      expect(find.text('Pick one'), findsOneWidget);
      for (final label in ['Alpha', 'Beta', 'Gamma']) {
        expect(find.text(label), findsOneWidget);
      }

      final alpha = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Alpha'),
      );
      final beta = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Beta'),
      );
      expect(alpha.selected, isTrue);
      expect(beta.selected, isFalse);
      // Only the selected row carries the check mark.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Alpha'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping an option closes the sheet and returns its value', (
      tester,
    ) async {
      final results = await _pumpOpener(tester);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(results, ['b']);
      expect(find.text('Pick one'), findsNothing);
    });

    testWidgets('dismissing without picking returns null', (tester) async {
      final results = await _pumpOpener(tester);

      await tester.tapAt(const Offset(10, 10)); // the scrim above the sheet
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });
}
