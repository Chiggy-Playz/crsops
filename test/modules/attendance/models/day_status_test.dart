import 'package:crs_ops/modules/attendance/models/day_status.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EffectiveStatusRow _row({
  String employeeId = '1',
  DateTime? date,
  String? firstHalfStatus,
  bool isExplicit = true,
  bool isWeekOff = false,
}) => EffectiveStatusRow(
  employeeId: employeeId,
  date: date ?? DateTime(2024, 6, 3),
  firstHalfStatus: firstHalfStatus,
  secondHalfStatus: firstHalfStatus,
  isExplicit: isExplicit,
  isWeekOff: isWeekOff,
);

void main() {
  group('representativeStatus', () {
    test('an explicit mark wins with its first-half status', () {
      expect(representativeStatus(_row(firstHalfStatus: 'present')), 'present');
    });

    test('an explicit mark beats week-off', () {
      expect(
        representativeStatus(_row(firstHalfStatus: 'present', isWeekOff: true)),
        'present',
      );
    });

    test('an unmarked week-off day reports week_off', () {
      expect(
        representativeStatus(_row(isExplicit: false, isWeekOff: true)),
        'week_off',
      );
    });

    test('an unmarked working day has no status', () {
      expect(representativeStatus(_row(isExplicit: false)), isNull);
    });

    test('an explicit row without a status has no status', () {
      expect(representativeStatus(_row(firstHalfStatus: null)), isNull);
    });
  });

  group('groupRowsByDate', () {
    test('groups rows under yyyy-MM-dd keys', () {
      final rows = [
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
        ),
        _row(
          employeeId: '2',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'absent',
        ),
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 4),
          firstHalfStatus: 'present',
        ),
      ];

      final grouped = groupRowsByDate(rows);

      expect(grouped.keys, {'2024-06-03', '2024-06-04'});
      expect(grouped['2024-06-03'], hasLength(2));
    });

    test('empty input maps to empty', () {
      expect(groupRowsByDate(const []), isEmpty);
    });
  });

  group('statusDotsFor', () {
    const colors = {
      'present': '#4CAF50',
      'absent': '#F44336',
      'week_off': '#9E9E9E',
    };

    test('one dot per distinct status on a mixed day', () {
      final dots = statusDotsFor([
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
        ),
        _row(
          employeeId: '2',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'absent',
        ),
      ], colors);

      expect(dots, hasLength(2));
    });

    test('dots follow status order, not row order', () {
      final dots = statusDotsFor([
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'absent',
        ),
        _row(
          employeeId: '2',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'present',
        ),
      ], colors);

      expect(dots, [const Color(0xFF4CAF50), const Color(0xFFF44336)]);
    });

    test('an explicit mark beats the week-off dot', () {
      final dots = statusDotsFor([
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          firstHalfStatus: 'present',
          isWeekOff: true,
        ),
      ], colors);

      expect(dots, [const Color(0xFF4CAF50)]);
    });

    test('unmarked non-week-off rows produce no dot', () {
      final dots = statusDotsFor([
        _row(employeeId: '1', date: DateTime(2024, 6, 4), isExplicit: false),
      ], colors);

      expect(dots, isEmpty);
    });

    test('an unmarked week-off day gets the week-off dot', () {
      final dots = statusDotsFor([
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 2),
          isExplicit: false,
          isWeekOff: true,
        ),
      ], colors);

      expect(dots, [const Color(0xFF9E9E9E)]);
    });

    test('an unknown status id falls back to grey', () {
      final dots = statusDotsFor([
        _row(
          employeeId: '1',
          date: DateTime(2024, 6, 3),
          firstHalfStatus: 'mystery',
        ),
      ], colors);

      expect(dots, [Colors.grey]);
    });
  });

  group('hasUnmarkedPastDay', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final pastDay = DateTime(yesterday.year, yesterday.month, yesterday.day);

    test('an active employee left unmarked on a past working day', () {
      final rows = [
        _row(employeeId: '1', date: pastDay, firstHalfStatus: 'present'),
        _row(employeeId: '2', date: pastDay, isExplicit: false),
      ];
      expect(hasUnmarkedPastDay(rows, pastDay), isTrue);
    });

    test('a fully marked day is not a gap', () {
      final rows = [
        _row(employeeId: '1', date: pastDay, firstHalfStatus: 'present'),
      ];
      expect(hasUnmarkedPastDay(rows, pastDay), isFalse);
    });

    test('an unmarked week-off is not a gap', () {
      final rows = [
        _row(
          employeeId: '1',
          date: pastDay,
          isExplicit: false,
          isWeekOff: true,
        ),
      ];
      expect(hasUnmarkedPastDay(rows, pastDay), isFalse);
    });

    test('today and later are never gaps yet', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final rows = [_row(employeeId: '1', date: today, isExplicit: false)];
      expect(hasUnmarkedPastDay(rows, today), isFalse);
    });
  });
}
