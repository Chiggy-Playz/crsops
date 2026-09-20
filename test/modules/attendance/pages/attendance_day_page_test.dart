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

final _activeMarkedWithTimesRow = EffectiveStatusRow(
  employeeId: '1',
  date: DateTime(2024, 6, 3),
  firstHalfStatus: 'present',
  secondHalfStatus: 'present',
  isExplicit: true,
  isWeekOff: false,
  timeIn: '10:35',
  timeOut: '18:40',
);

Widget _wrap({required FakeAttendanceRepository attendanceRepo}) =>
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
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        statusTypeRepositoryProvider.overrideWithValue(
          FakeStatusTypeRepository(seed: _statusTypes),
        ),
      ],
      child: MaterialApp(home: AttendanceDayPage(date: DateTime(2024, 6, 3))),
    );

/// Scopes text lookups to the mark sheet: the tile behind it can show the
/// same label (e.g. its "Present" button), so a bare find.text is ambiguous.
Finder _sheetText(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('mark-status-1')));
  await tester.pumpAndSettle();
}

Future<void> _expandTimes(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('mark-status-advanced')));
  await tester.pumpAndSettle();
}

Future<void> _acceptTimePicker(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  group('AttendanceDayPage', () {
    testWidgets(
      'picking Present from the status menu marks the employee full-day present',
      (tester) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeUnmarkedRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await tester.tap(_sheetText('Present'));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'present');
        expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'present');
      },
    );

    testWidgets(
      'picking Absent from the status menu marks the employee full-day absent',
      (tester) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeUnmarkedRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await tester.tap(_sheetText('Absent'));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(attendanceRepo.markedDays.first['firstHalfStatus'], 'absent');
        expect(attendanceRepo.markedDays.first['secondHalfStatus'], 'absent');
      },
    );

    testWidgets(
      'mark all present shows a confirm dialog before calling the repository',
      (tester) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeUnmarkedRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('mark-all-present-button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mark-all-present-confirm-dialog')),
          findsOneWidget,
        );
        expect(attendanceRepo.markedAllPresentDates, isEmpty);

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedAllPresentDates, hasLength(1));
      },
    );

    testWidgets(
      'an employee not yet active on this date is excluded from the list',
      (tester) async {
        // No rangeStatusSeed row for employee '1' on this date at all — simulates
        // an employee who joined after this date.
        final attendanceRepo = FakeAttendanceRepository();
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        expect(find.text('Ramesh'), findsNothing);
        expect(find.text('No active employees for this date'), findsOneWidget);
      },
    );

    testWidgets('an unmarked week-off day shows Week off instead of Unmarked', (
      tester,
    ) async {
      final weekOffRow = EffectiveStatusRow(
        employeeId: '1',
        date: DateTime(2024, 6, 3),
        isExplicit: false,
        isWeekOff: true,
      );
      final attendanceRepo = FakeAttendanceRepository(
        rangeStatusSeed: [weekOffRow],
      );
      await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
      await tester.pumpAndSettle();

      expect(find.text('Week off'), findsWidgets);
      expect(find.text('Unmarked'), findsNothing);
    });

    group('time entry', () {
      testWidgets('time picker entry is saved through the advanced section', (
        tester,
      ) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeUnmarkedRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await _expandTimes(tester);

        await tester.tap(find.byKey(const Key('mark-status-time-in')));
        await tester.pumpAndSettle();
        await _acceptTimePicker(tester);

        await tester.tap(find.byKey(const Key('mark-status-save-times')));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        // Halves pass through as null here — the repository (not the UI)
        // applies the presence default.
        expect(attendanceRepo.markedDays.first['firstHalfStatus'], isNull);
        expect(attendanceRepo.markedDays.first['secondHalfStatus'], isNull);
        expect(
          attendanceRepo.markedDays.first['timeIn'],
          matches(RegExp(r'^\d{2}:\d{2}$')),
        );
        expect(attendanceRepo.markedDays.first['timeOut'], isNull);
      });

      testWidgets('time out is saved alongside time in', (tester) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeUnmarkedRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await _expandTimes(tester);

        await tester.tap(find.byKey(const Key('mark-status-time-in')));
        await tester.pumpAndSettle();
        await _acceptTimePicker(tester);

        await tester.tap(find.byKey(const Key('mark-status-time-out')));
        await tester.pumpAndSettle();
        await _acceptTimePicker(tester);

        await tester.tap(find.byKey(const Key('mark-status-save-times')));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(
          attendanceRepo.markedDays.first['timeIn'],
          matches(RegExp(r'^\d{2}:\d{2}$')),
        );
        expect(
          attendanceRepo.markedDays.first['timeOut'],
          matches(RegExp(r'^\d{2}:\d{2}$')),
        );
      });

      testWidgets('quick full-day tap preserves already-entered times', (
        tester,
      ) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeMarkedWithTimesRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await tester.tap(_sheetText('Present'));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(attendanceRepo.markedDays.first['timeIn'], '10:35');
        expect(attendanceRepo.markedDays.first['timeOut'], '18:40');
      });

      testWidgets('clearing a time then saving keeps it cleared', (
        tester,
      ) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeMarkedWithTimesRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await _expandTimes(tester);

        await tester.tap(find.byKey(const Key('mark-status-time-in-clear')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('mark-status-save-times')));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(attendanceRepo.markedDays.first['timeIn'], isNull);
        expect(attendanceRepo.markedDays.first['timeOut'], '18:40');
      });

      testWidgets('clearing a time then quick-picking does not resurrect it', (
        tester,
      ) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeMarkedWithTimesRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await _expandTimes(tester);

        await tester.tap(find.byKey(const Key('mark-status-time-in-clear')));
        await tester.pumpAndSettle();

        await tester.tap(_sheetText('Present'));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, hasLength(1));
        expect(attendanceRepo.markedDays.first['timeIn'], isNull);
        expect(attendanceRepo.markedDays.first['timeOut'], '18:40');
      });

      testWidgets('unmark from the sheet deletes the marking', (tester) async {
        final attendanceRepo = FakeAttendanceRepository(
          rangeStatusSeed: [_activeMarkedWithTimesRow],
        );
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        await _openSheet(tester);
        await tester.tap(find.byKey(const Key('mark-status-unmark')));
        await tester.pumpAndSettle();

        expect(attendanceRepo.markedDays, isEmpty);
        expect(attendanceRepo.unmarkedDays, hasLength(1));
      });

      testWidgets('a time-in-only day shows just its time in', (tester) async {
        final row = EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
          secondHalfStatus: 'present',
          isExplicit: true,
          isWeekOff: false,
          // Postgres `time` reads back with seconds — must still parse and
          // render locale-aware rather than raw.
          timeIn: '10:35:00',
        );
        final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [row]);
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        expect(find.textContaining('in 10:35 AM'), findsOneWidget);
      });

      testWidgets('a malformed stored time falls back instead of crashing', (
        tester,
      ) async {
        final row = EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
          secondHalfStatus: 'present',
          isExplicit: true,
          isWeekOff: false,
          timeIn: '99:99',
        );
        final attendanceRepo = FakeAttendanceRepository(rangeStatusSeed: [row]);
        await tester.pumpWidget(_wrap(attendanceRepo: attendanceRepo));
        await tester.pumpAndSettle();

        expect(find.textContaining('99:99'), findsOneWidget);
      });
    });
  });
}
