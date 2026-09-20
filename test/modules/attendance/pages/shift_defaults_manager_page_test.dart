import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:crs_ops/modules/attendance/pages/shift_defaults_manager_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_shift_defaults_repository.dart';

void main() {
  testWidgets('shows the shift-defaults history', (tester) async {
    final repo = FakeShiftDefaultsRepository(
      seed: [
        ShiftDefaults(
          id: '1',
          effectiveFrom: DateTime(2000, 1, 1),
          defaultStart: '10:30:00',
          defaultEnd: '18:30:00',
          weekOffDays: const [7],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shiftDefaultsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ShiftDefaultsManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('10:30'), findsOneWidget);
  });

  testWidgets('adding through the dialog appends to history', (tester) async {
    final repo = FakeShiftDefaultsRepository(
      seed: [
        ShiftDefaults(
          id: '1',
          effectiveFrom: DateTime(2000, 1, 1),
          defaultStart: '10:30:00',
          defaultEnd: '18:30:00',
          weekOffDays: const [7],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shiftDefaultsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: ShiftDefaultsManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New shift default'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final history = await repo.fetchHistory();
    expect(history, hasLength(2));
  });
}
