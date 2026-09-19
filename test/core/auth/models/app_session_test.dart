import 'package:crs_ops/core/auth/models/app_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSession', () {
    test('isAdminOrAbove is true for admin and superadmin, false otherwise', () {
      const admin = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      const superadmin = AppSession(userId: 'u2', email: 'b@x.com', role: AppRole.superadmin, moduleAccess: {});
      const employee = AppSession(userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {});
      const noRole = AppSession(userId: 'u4', email: 'd@x.com', role: null, moduleAccess: {});

      expect(admin.isAdminOrAbove, isTrue);
      expect(superadmin.isAdminOrAbove, isTrue);
      expect(employee.isAdminOrAbove, isFalse);
      expect(noRole.isAdminOrAbove, isFalse);
    });

    test('admin-or-above has module access regardless of moduleAccess set', () {
      const admin = AppSession(userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {});
      expect(admin.hasModuleAccess('attendance'), isTrue);
    });

    test('employee has module access only if explicitly granted', () {
      const withAccess = AppSession(
        userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {'attendance'},
      );
      const withoutAccess = AppSession(userId: 'u3', email: 'c@x.com', role: AppRole.employee, moduleAccess: {});

      expect(withAccess.hasModuleAccess('attendance'), isTrue);
      expect(withoutAccess.hasModuleAccess('attendance'), isFalse);
    });

    test('round-trips through JSON', () {
      const session = AppSession(
        userId: 'u1', email: 'a@x.com', role: AppRole.admin, moduleAccess: {'attendance'},
      );
      final json = session.toMap();
      final decoded = AppSessionMapper.fromMap(json);
      expect(decoded, session);
    });
  });
}
