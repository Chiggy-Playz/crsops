import 'package:crs_ops/modules/attendance/repositories/attendance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyPresenceDefault', () {
    test('a null half defaults to the seeded present status', () {
      expect(applyPresenceDefault(null), defaultPresenceStatusId);
      expect(applyPresenceDefault(null), 'present');
    });

    test('an explicit half passes through untouched', () {
      expect(applyPresenceDefault('absent'), 'absent');
      expect(applyPresenceDefault('leave'), 'leave');
    });
  });
}
