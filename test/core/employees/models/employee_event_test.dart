import 'package:crs_ops/core/employees/models/employee_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'EmployeeEvent round-trips through JSON shapes matching Postgres output',
    () {
      final json = {
        'id': '22222222-2222-2222-2222-222222222222',
        'employee_id': '11111111-1111-1111-1111-111111111111',
        'event_type': 'joined',
        'event_date': '2024-01-10',
        'note': null,
        'created_by': null,
        'created_at': '2024-01-10T00:00:00.000Z',
      };

      final event = EmployeeEventMapper.fromMap(json);

      expect(event.eventType, 'joined');
      expect(event.eventDate, DateTime.parse('2024-01-10'));
      expect(event.note, isNull);
    },
  );
}
