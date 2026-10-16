import 'package:crs_ops/modules/attendance/models/status_ids.dart';
import 'package:crs_ops/modules/attendance/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyPresenceDefault', () {
    test('a null half defaults to the seeded present status', () {
      expect(applyPresenceDefault(null), StatusIds.present);
    });

    test('an explicit status passes through untouched', () {
      expect(applyPresenceDefault('absent'), 'absent');
      expect(applyPresenceDefault('leave'), 'leave');
      expect(applyPresenceDefault(''), '');
    });
  });

  group('markDayPayload', () {
    test('builds the full upsert payload', () {
      expect(
        markDayPayload(
          employeeId: 'e1',
          date: '2024-06-03',
          status: 'half_day',
          timeIn: '10:35',
          timeOut: '18:40',
          note: 'late train',
        ),
        {
          'employee_id': 'e1',
          'date': '2024-06-03',
          'status': 'half_day',
          'time_in': '10:35',
          'time_out': '18:40',
          'note': 'late train',
        },
      );
    });

    test('a null status gets the presence default, times stay nullable', () {
      final payload = markDayPayload(employeeId: 'e1', date: '2024-06-03');

      expect(payload['status'], StatusIds.present);
      expect(payload['time_in'], isNull);
      expect(payload['time_out'], isNull);
      expect(payload['note'], isNull);
    });
  });
}
