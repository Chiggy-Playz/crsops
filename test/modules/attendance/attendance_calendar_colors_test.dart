import 'package:crs_ops/modules/attendance/attendance_calendar_colors.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EffectiveStatusRow _row({
  required String employeeId,
  required DateTime date,
  String? firstHalfStatus,
  bool isExplicit = true,
  bool isWeekOff = false,
}) => EffectiveStatusRow(
  employeeId: employeeId,
  date: date,
  firstHalfStatus: firstHalfStatus,
  secondHalfStatus: firstHalfStatus,
  isExplicit: isExplicit,
  isWeekOff: isWeekOff,
);

void main() {
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
}
