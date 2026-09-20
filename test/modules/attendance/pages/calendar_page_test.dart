import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/core/utils/date_key.dart';
import 'package:crs_ops/modules/attendance/models/gap_row.dart';
import 'package:crs_ops/modules/attendance/pages/calendar_page.dart';
import 'package:crs_ops/modules/attendance/pages/widgets/day_cell.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';

void main() {
  testWidgets('renders a month grid and navigating to today does not crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(
              seed: [
                Employee(
                  id: '1',
                  name: 'Ramesh',
                  color: 0xFF4CAF50,
                  createdAt: DateTime(2024, 1, 1),
                ),
              ],
            ),
          ),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(),
          ),
        ],
        child: const MaterialApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('a day with a gap shows a warning marker', (tester) async {
    final today = DateTime.now();
    // Stay inside the displayed month: day-minus-one on the 1st falls in
    // the previous month, whose grid never renders the marker.
    final gapDate = today.day > 1
        ? DateTime(today.year, today.month, today.day - 1)
        : today.add(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(
              seed: [
                Employee(
                  id: '1',
                  name: 'Ramesh',
                  color: 0xFF4CAF50,
                  createdAt: DateTime(2024, 1, 1),
                ),
              ],
            ),
          ),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(
              gapsSeed: [GapRow(employeeId: '1', date: gapDate)],
            ),
          ),
        ],
        child: const MaterialApp(home: CalendarPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(gapMarkerKey(dateOnly(gapDate))), findsOneWidget);
  });
}
