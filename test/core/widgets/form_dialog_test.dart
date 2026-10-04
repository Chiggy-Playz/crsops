import 'package:crs_ops/core/widgets/form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void _setSize(WidgetTester tester, Size size) {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
  addTearDown(view.reset);
}

/// A one-field form: [saves] counts onSave calls that passed validation.
Future<List<int>> _pumpForm(WidgetTester tester) async {
  final saves = <int>[];
  final formKey = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => StatefulBuilder(
              builder: (context, _) => FormDialog(
                title: 'Add thing',
                formKey: formKey,
                saving: false,
                saveButtonKey: const Key('save'),
                onSave: () {
                  if (formKey.currentState!.validate()) saves.add(1);
                },
                children: [
                  TextFormField(
                    key: const Key('name'),
                    validator: (v) => (v ?? '').isEmpty ? 'Enter a name' : null,
                  ),
                ],
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return saves;
}

void main() {
  group('FormDialog', () {
    testWidgets('is full-screen with Save in the app bar on phones', (
      tester,
    ) async {
      _setSize(tester, const Size(400, 800));
      await _pumpForm(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(CloseButton), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Save')),
        findsOneWidget,
      );
    });

    testWidgets('is a centred dialog with Cancel and Save on wide screens', (
      tester,
    ) async {
      _setSize(tester, const Size(1200, 800));
      await _pumpForm(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      expect(
        tester.getSize(find.byType(Form)).width,
        lessThanOrEqualTo(FormDialog.maxWidth),
      );
    });

    testWidgets('Save with a missing field shows why instead of saving', (
      tester,
    ) async {
      _setSize(tester, const Size(1200, 800));
      final saves = await _pumpForm(tester);

      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name'), findsOneWidget);
      expect(saves, isEmpty);
    });

    testWidgets('Ctrl+Enter saves', (tester) async {
      _setSize(tester, const Size(1200, 800));
      final saves = await _pumpForm(tester);

      await tester.enterText(find.byKey(const Key('name')), 'Asha');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(saves, [1]);
    });
  });
}
