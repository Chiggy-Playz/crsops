import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/models/event_type.dart';
import 'package:crs_ops/core/employees/pages/event_types_manager_page.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_event_type_repository.dart';

void main() {
  testWidgets('lists every event type with its current icon/color', (
    tester,
  ) async {
    final repo = FakeEventTypeRepository(
      seed: [
        const EventType(
          id: 'joined',
          statusEffect: EmploymentStatus.active,
          iconName: 'check',
          colorHex: '#4CAF50',
        ),
        const EventType(id: 'promotion', description: 'Promoted'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [eventTypeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: EventTypesManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Promotion'), findsOneWidget);
  });

  testWidgets(
    'tapping a type opens an edit dialog that updates its icon/color',
    (tester) async {
      final repo = FakeEventTypeRepository(
        seed: [const EventType(id: 'promotion', description: 'Promoted')],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [eventTypeRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: EventTypesManagerPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Promotion'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-type-edit-dialog')), findsOneWidget);

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      // The menu overlay renders on top, i.e. last in the tree.
      await tester.tap(find.text('Check').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final types = await repo.fetchAll();
      expect(types.single.iconName, 'check');
    },
  );
}
