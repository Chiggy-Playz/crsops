import 'package:crs_ops/modules/attendance/models/gap_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GapRow', () {
    test('decodes a realistic RPC row', () {
      final row = GapRowMapper.fromMap({
        'employee_id': '1',
        'date': '2024-06-03',
      });

      expect(row.employeeId, '1');
      expect(row.date, DateTime(2024, 6, 3));
    });

    test('round-trips through a map', () {
      final row = GapRowMapper.fromMap(
        GapRow(employeeId: '1', date: DateTime(2024, 6, 3)).toMap(),
      );

      expect(row.employeeId, '1');
      // Same UTC-serialization caveat as DerivedFlagsRow: same instant.
      expect(row.date.isAtSameMomentAs(DateTime(2024, 6, 3)), isTrue);
    });
  });
}
