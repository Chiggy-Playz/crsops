import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/providers/employee_providers.dart';
import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/pages/report/report_page.dart';
import 'package:crs_ops/modules/attendance/providers/attendance_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/employees/fakes/fake_employee_repository.dart';
import '../../fakes/fake_attendance_repository.dart';
import '../../fakes/fake_status_type_repository.dart';

Employee _employee(String id, String name) =>
    Employee(id: id, name: name, color: 0xFF4CAF50, createdAt: DateTime(2024));

Widget _wrap({
  List<Employee>? employees,
  List<DerivedFlagsRow>? derivedFlags,
}) => ProviderScope(
  overrides: [
    employeeRepositoryProvider.overrideWithValue(
      FakeEmployeeRepository(seed: employees ?? [_employee('1', 'Ramesh')]),
    ),
    attendanceRepositoryProvider.overrideWithValue(
      FakeAttendanceRepository(derivedFlagsSeed: derivedFlags),
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

DerivedFlagsRow _flag({
  required String employeeId,
  bool isLate = false,
  bool isEarly = false,
  int overtimeMinutes = 0,
}) => DerivedFlagsRow(
  employeeId: employeeId,
  date: DateTime.now(),
  workedMinutes: 480,
  isLate: isLate,
  isEarly: isEarly,
  overtimeMinutes: overtimeMinutes,
);

void main() {
  group('ReportPage', () {
    testWidgets(
      'defaults to this month and shows the report body immediately',
      (tester) async {
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle();

        expect(find.text('This month'), findsOneWidget);
        expect(find.text('Late / early / overtime'), findsOneWidget);
      },
    );

    testWidgets('has an employee filter defaulting to All employees', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('All employees'), findsOneWidget);
    });

    group('exceptions', () {
      testWidgets('exception rows show which employee the flag belongs to', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            employees: [_employee('1', 'Ramesh'), _employee('2', 'Suresh')],
            derivedFlags: [_flag(employeeId: '2', isEarly: true)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suresh'), findsOneWidget);
        expect(find.textContaining('Left early'), findsOneWidget);
      });

      testWidgets('a flag for an unknown employee still renders', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(
            employees: [_employee('1', 'Ramesh')],
            derivedFlags: [_flag(employeeId: 'ghost', isLate: true)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unknown employee'), findsOneWidget);
        // Scoped with the separator: the section header also contains "Late".
        expect(find.textContaining('· Late'), findsOneWidget);
      });

      testWidgets('overtime renders in hours, not raw minutes', (tester) async {
        await tester.pumpWidget(
          _wrap(
            employees: [_employee('1', 'Ramesh')],
            derivedFlags: [
              _flag(employeeId: '1', overtimeMinutes: 120),
              _flag(employeeId: '1', overtimeMinutes: 45),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('+2h overtime'), findsOneWidget);
        expect(find.textContaining('+45m overtime'), findsOneWidget);
        expect(find.textContaining('+120m'), findsNothing);
      });
    });
  });
}
