import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/pages/attendance_day_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';

void main() {
  testWidgets('quick-tap present marks the employee full-day present', (tester) async {
    final attendanceRepo = FakeAttendanceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        ],
        child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-present-1')));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedDays, hasLength(1));
    expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'present');
    expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'present');
  });

  testWidgets('mark all present shows a confirm dialog before calling the repository', (tester) async {
    final attendanceRepo = FakeAttendanceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeRepositoryProvider.overrideWithValue(
            FakeEmployeeRepository(seed: [
              Employee(id: '1', name: 'Ramesh', color: 0xFF4CAF50, createdAt: DateTime(2024, 1, 1)),
            ]),
          ),
          attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        ],
        child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mark-all-present-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mark-all-present-confirm-dialog')), findsOneWidget);
    expect(attendanceRepo.markedAllPresentDates, isEmpty);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(attendanceRepo.markedAllPresentDates, hasLength(1));
  });
}
