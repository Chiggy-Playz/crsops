import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DerivedFlagsRow', () {
    test('decodes a realistic RPC row', () {
      final row = DerivedFlagsRowMapper.fromMap({
        'employee_id': '1',
        'date': '2024-06-03',
        'time_in': '10:35:00',
        'time_out': '18:40:00',
        'worked_minutes': 485,
        'is_late': true,
        'is_early': false,
        'overtime_minutes': 5,
      });

      expect(row.employeeId, '1');
      expect(row.date, DateTime(2024, 6, 3));
      expect(row.timeIn, '10:35:00');
      expect(row.timeOut, '18:40:00');
      expect(row.workedMinutes, 485);
      expect(row.isLate, isTrue);
      expect(row.isEarly, isFalse);
      expect(row.overtimeMinutes, 5);
    });

    test('round-trips through a map', () {
      final row = DerivedFlagsRowMapper.fromMap(
        DerivedFlagsRow(
              employeeId: '1',
              date: DateTime(2024, 6, 3),
              timeIn: '10:35',
              timeOut: null,
              workedMinutes: 0,
              isLate: false,
              isEarly: false,
              overtimeMinutes: 0,
            ).toMap(),
      );

      expect(row.employeeId, '1');
      // toMap serializes to UTC ISO; the wall-clock rendering shifts but
      // the instant survives the round trip.
      expect(row.date.isAtSameMomentAs(DateTime(2024, 6, 3)), isTrue);
      expect(row.timeIn, '10:35');
      expect(row.workedMinutes, 0);
    });
  });
}
