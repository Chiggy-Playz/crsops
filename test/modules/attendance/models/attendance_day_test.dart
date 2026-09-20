import 'package:crs_ops/modules/attendance/models/attendance_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AttendanceDay round-trips through JSON with nullable time fields', () {
    final json = {
      'id': '22222222-2222-2222-2222-222222222222',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'date': '2024-06-01',
      'first_half_status': 'present',
      'second_half_status': 'present',
      'time_in': null,
      'time_out': null,
      'note': null,
    };

    final day = AttendanceDayMapper.fromMap(json);

    expect(day.firstHalfStatus, 'present');
    expect(day.timeIn, isNull);
  });
}
