import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EffectiveStatusRow round-trips through effective_range_status output shape', () {
    final json = {
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'date': '2024-06-02',
      'first_half_status': null,
      'second_half_status': null,
      'is_explicit': false,
      'is_week_off': true,
      'time_in': null,
      'time_out': null,
      'note': null,
    };

    final row = EffectiveStatusRowMapper.fromMap(json);

    expect(row.isWeekOff, isTrue);
    expect(row.isExplicit, isFalse);
  });
}
