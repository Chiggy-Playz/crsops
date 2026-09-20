import 'package:crs_ops/modules/attendance/day_status.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:flutter_test/flutter_test.dart';

EffectiveStatusRow _row({
  String? firstHalfStatus,
  bool isExplicit = true,
  bool isWeekOff = false,
}) => EffectiveStatusRow(
  employeeId: '1',
  date: DateTime(2024, 6, 3),
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
}
