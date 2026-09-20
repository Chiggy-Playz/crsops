import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/status_types_manager_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_status_type_repository.dart';

void main() {
  testWidgets('lists every status type', (tester) async {
    final repo = FakeStatusTypeRepository(seed: [
      const StatusType(id: 'present', label: 'Present', iconName: 'check', colorHex: '#4CAF50'),
      const StatusType(id: 'absent', label: 'Absent', iconName: 'close', colorHex: '#F44336'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [statusTypeRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: StatusTypesManagerPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
  });
}
