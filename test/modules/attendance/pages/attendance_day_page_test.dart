import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/attendance_day_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';
import '../fakes/fake_status_type_repository.dart';

const _statusTypes = [
  StatusType(id: 'present', label: 'Present', iconName: 'check', colorHex: '#4CAF50'),
  StatusType(id: 'absent', label: 'Absent', iconName: 'close', colorHex: '#F44336'),
];

// effectiveRangeStatusProvider (which is what decides which employees are
// "active" on the page's date) always returns a row for every employee who
// was active that day, marked or not — so tests need this seeded even for an
// unmarked employee, or the page correctly shows nobody at all.
final _activeUnmarkedRow = EffectiveStatusRow(
  employeeId: '1',
  date: DateTime(2024, 6, 3),
  isExplicit: false,
  isWeekOff: false,
);

Widget _wrap({required FakeAttendanceRepository attendanceRepo}) => ProviderScope(
      overrides: [
        employeeRepositoryProvider.overrideWithValue(
          FakeEmployeeRepository(seed: [
            Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
          ]),
        ),
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        statusTypeRepositoryProvider.overrideWithValue(FakeStatusTypeRepository(seed: _statusTypes)),
      ],
      child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
    );

void main() {
  testWidgets('picking Present from the status menu marks the employee full-day present', (tester) async {
    final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [_activeUnmarkedRow]);
    await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-status-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Present'));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedDays, hasLength(1));
    expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'present');
    expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'present');
  });

  testWidgets('picking Absent from the status menu marks the employee full-day absent', (tester) async {
    final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [_activeUnmarkedRow]);
    await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-status-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Absent'));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedDays, hasLength(1));
    expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'absent');
    expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'absent');
  });

  testWidgets('mark all present shows a confirm dialog before calling the repository', (tester) async {
    final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [_activeUnmarkedRow]);
    await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-all-present-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark-all-present-confirm-dialog')), findsOneWidget);
    expect(attendanceRepo.markedAllPresentDates, isEmpty);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedAllPresentDates, hasLength(1));
  });

  testWidgets('an employee not yet active on this date is excluded from the list', (tester) async {
    // No rangeStatusSeed row for employee '1' on this date at all — simulates
    // an employee who joined after this date.
    final attendanceRepo = FakeAttendanceRepository();
    await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh'), findsNothing);
    expect(find.text('No active employees for this date'), findsOneWidget);
  });

  testWidgets('an unmarked week-off day shows Week off instead of Unmarked', (tester) async {
    final weekOffRow = EffectiveStatusRow(
      employeeId: '1',
      date: DateTime(2024, 6, 3),
      isExplicit: false,
      isWeekOff: true,
    );
    final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [weekOffRow]);
    await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
    await tester.pumpAndSettle();

    expect(find.text('Week off'), findsWidgets);
    expect(find.text('Unmarked'), findsNothing);
  });
}
