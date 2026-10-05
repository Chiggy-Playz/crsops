import 'package:crs_ops/modules/attendance/models/status_ids.dart';
import 'package:crs_ops/modules/attendance/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyPresenceDefault', () {
    test('a null half defaults to the seeded present status', () {
      expect(applyPresenceDefault(null), StatusIds.present);
    });

    test('an explicit half passes through untouched', () {
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
          firstHalfStatus: 'present',
          secondHalfStatus: 'absent',
          timeIn: '10:35',
          timeOut: '18:40',
          note: 'late train',
        ),
        {
          'employee_id': 'e1',
          'date': '2024-06-03',
          'first_half_status': 'present',
          'second_half_status': 'absent',
          'time_in': '10:35',
          'time_out': '18:40',
          'note': 'late train',
        },
      );
    });

    test('null halves get the presence default, times stay nullable', () {
      final payload = markDayPayload(employeeId: 'e1', date: '2024-06-03');

      expect(payload['first_half_status'], StatusIds.present);
      expect(payload['second_half_status'], StatusIds.present);
      expect(payload['time_in'], isNull);
      expect(payload['time_out'], isNull);
      expect(payload['note'], isNull);
    });
  });
}
