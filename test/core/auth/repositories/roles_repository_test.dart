import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:crs_ops/core/auth/repositories/roles_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('highestRole', () {
    test('no rows means no role', () {
      expect(highestRole(const []), isNull);
    });

    test('a single role wins by itself', () {
      expect(highestRole(const ['employee']), AppRole.employee);
      expect(highestRole(const ['admin']), AppRole.admin);
      expect(highestRole(const ['superadmin']), AppRole.superadmin);
    });

    test('superadmin beats admin beats employee', () {
      expect(
        highestRole(const ['employee', 'admin', 'superadmin']),
        AppRole.superadmin,
      );
      expect(highestRole(const ['employee', 'admin']), AppRole.admin);
    });

    test('unknown ids fall back to employee, never null', () {
      expect(highestRole(const ['weird']), AppRole.employee);
    });
  });
}
