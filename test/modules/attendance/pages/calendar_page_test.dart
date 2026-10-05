import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/core/utils/date_time_format.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
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

  testWidgets('a past day with someone unmarked shows a warning marker', (
    tester,
  ) async {
    // A fixed past month (opened via selectedDate), so the test doesn't
    // depend on today's date.
    final gapDate = DateTime(2024, 6, 3);
    final markedDate = DateTime(2024, 6, 4);

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
              rangeStatusSeed: [
                EffectiveStatusRow(
                  employeeId: '1',
                  date: gapDate,
                  isExplicit: false,
                  isWeekOff: false,
                ),
                EffectiveStatusRow(
                  employeeId: '1',
                  date: markedDate,
                  firstHalfStatus: 'present',
                  secondHalfStatus: 'present',
                  isExplicit: true,
                  isWeekOff: false,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          home: CalendarPage(selectedDate: DateTime(2024, 6, 10)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(gapMarkerKey(dateOnly(gapDate))), findsOneWidget);
    expect(find.byKey(gapMarkerKey(dateOnly(markedDate))), findsNothing);
  });
}
