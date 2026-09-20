import 'package:crs_ops/modules/attendance/models/shift_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShiftDefaults round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '11111111-1111-1111-1111-111111111111',
      'effective_from': '2000-01-01',
      'default_start': '10:30:00',
      'default_end': '18:30:00',
      'week_off_days': [7],
    };

    final shift = ShiftDefaultsMapper.fromMap(json);

    expect(shift.effectiveFrom, DateTime.parse('2000-01-01'));
    expect(shift.defaultStart, '10:30:00');
    expect(shift.weekOffDays, [7]);
  });
}
