import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips an event-kind row from core.employee_timeline', () {
    final json = {
      'id': '22222222-2222-2222-2222-222222222222',
      'employee_id': '11111111-1111-1111-1111-111111111111',
      'entry_date': '2024-01-10',
      'kind': 'event',
      'label': 'joined',
      'note': null,
      'amount': null,
    };

    final entry = TimelineEntryMapper.fromMap(json);

    expect(entry.kind, 'event');
    expect(entry.label, 'joined');
  });
}
