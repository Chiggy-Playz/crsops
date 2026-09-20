import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/status_type.dart';
import 'package:crs_ops/modules/attendance/report_calculations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeStatusSummary', () {
    const statusTypes = [
      StatusType(id: 'present', label: 'Present'),
      StatusType(id: 'absent', label: 'Absent'),
      StatusType(id: 'week_off', label: 'Week Off'),
    ];

    test('an explicit day counts toward its first_half_status bucket', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
          secondHalfStatus: 'absent',
          isExplicit: true,
          isWeekOff: false,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['present'], 1);
      expect(summary['absent'], 0);
    });

    test('explicit beats computed week-off — an explicitly marked Sunday counts by its status, not week_off', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          firstHalfStatus: 'present',
          secondHalfStatus: 'present',
          isExplicit: true,
          isWeekOff: true,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['present'], 1);
      expect(summary['week_off'], 0);
    });

    test('an unexplicit week-off day counts as week_off', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          isExplicit: false,
          isWeekOff: true,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['week_off'], 1);
      expect(summary['unmarked'], 0);
    });

    test('a genuine gap (not explicit, not week off) counts as unmarked', () {
      final rows = [
        EffectiveStatusRow(
          employeeId: '1',
          date: DateTime(2024, 6, 4),
          isExplicit: false,
          isWeekOff: false,
        ),
      ];

      final summary = computeStatusSummary(rows, statusTypes);

      expect(summary['unmarked'], 1);
    });

    test('every status type starts at zero even with no matching rows', () {
      final summary = computeStatusSummary(const [], statusTypes);

      expect(summary['present'], 0);
      expect(summary['absent'], 0);
      expect(summary['week_off'], 0);
      expect(summary['unmarked'], 0);
    });
  });

  group('filterExceptions', () {
    test('includes a late row, an early row, and an overtime row; excludes an all-clear row', () {
      final rows = [
        DerivedFlagsRow(
          employeeId: '1',
          date: DateTime(2024, 6, 1),
          workedMinutes: 480,
          isLate: false,
          isEarly: false,
          overtimeMinutes: 0,
        ),
        DerivedFlagsRow(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          workedMinutes: 450,
          isLate: true,
          isEarly: false,
          overtimeMinutes: 0,
        ),
        DerivedFlagsRow(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          workedMinutes: 420,
          isLate: false,
          isEarly: true,
          overtimeMinutes: 0,
        ),
        DerivedFlagsRow(
          employeeId: '1',
          date: DateTime(2024, 6, 4),
          workedMinutes: 600,
          isLate: false,
          isEarly: false,
          overtimeMinutes: 120,
        ),
      ];

      final exceptions = filterExceptions(rows);

      expect(exceptions, hasLength(3));
      expect(
        exceptions.map((r) => r.date),
        isNot(contains(DateTime(2024, 6, 1))),
      );
    });
  });

  group('formatOvertime', () {
    test('under an hour stays in minutes', () {
      expect(formatOvertime(45), '45m');
    });

    test('zero minutes stays minutes', () {
      expect(formatOvertime(0), '0m');
    });

    test('the hour boundary flips to hours', () {
      expect(formatOvertime(59), '59m');
      expect(formatOvertime(60), '1h');
      expect(formatOvertime(61), '1h 1m');
    });

    test('exact hours drop the minutes', () {
      expect(formatOvertime(120), '2h');
    });

    test('mixed hours and minutes show both', () {
      expect(formatOvertime(90), '1h 30m');
    });

    test('a full overnight shift reads in hours', () {
      expect(formatOvertime(420), '7h');
    });
  });
}
