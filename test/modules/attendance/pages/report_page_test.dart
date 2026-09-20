import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/report_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/employees/fakes/fake_employee_repository.dart';
import '../fakes/fake_attendance_repository.dart';
import '../fakes/fake_status_type_repository.dart';

void main() {
  Widget wrap() => ProviderScope(
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
      statusTypeRepositoryProvider.overrideWithValue(
        FakeStatusTypeRepository(
          seed: const [
            StatusType(
              id: 'present',
              label: 'Present',
              iconName: 'check',
              colorHex: '#4CAF50',
            ),
            StatusType(
              id: 'absent',
              label: 'Absent',
              iconName: 'close',
              colorHex: '#F44336',
            ),
          ],
        ),
      ),
    ],
    child: const MaterialApp(home: ReportPage()),
  );

  testWidgets('defaults to this month and shows the report body immediately', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Late / early / overtime'), findsOneWidget);
  });

  testWidgets('has an employee filter defaulting to All employees', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('All employees'), findsOneWidget);
  });

  testWidgets('exception rows show which employee the flag belongs to', (
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
                Employee(
                  id: '2',
                  name: 'Suresh',
                  color: 0xFF2196F3,
                  createdAt: DateTime(2024, 1, 1),
                ),
              ],
            ),
          ),
          attendanceRepositoryProvider.overrideWithValue(
            FakeAttendanceRepository(
              derivedFlagsSeed: [
                DerivedFlagsRow(
                  employeeId: '2',
                  date: DateTime.now(),
                  workedMinutes: 400,
                  isLate: false,
                  isEarly: true,
                  overtimeMinutes: 0,
                ),
              ],
            ),
          ),
          statusTypeRepositoryProvider.overrideWithValue(
            FakeStatusTypeRepository(
              seed: const [
                StatusType(
                  id: 'present',
                  label: 'Present',
                  iconName: 'check',
                  colorHex: '#4CAF50',
                ),
                StatusType(
                  id: 'absent',
                  label: 'Absent',
                  iconName: 'close',
                  colorHex: '#F44336',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: ReportPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suresh'), findsOneWidget);
    expect(find.textContaining('Left early'), findsOneWidget);
  });
}
