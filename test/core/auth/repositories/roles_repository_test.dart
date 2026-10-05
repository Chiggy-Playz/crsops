import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/repositories/roles_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roleFromId', () {
    test('known ids map to their role', () {
      expect(roleFromId('employee'), AppRole.employee);
      expect(roleFromId('admin'), AppRole.admin);
      expect(roleFromId('superadmin'), AppRole.superadmin);
    });

    test('unknown ids fall back to employee', () {
      expect(roleFromId('weird'), AppRole.employee);
    });
  });
}
