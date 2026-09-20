import 'package:crs_ops/core/auth/repositories/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupModuleAccessByUser', () {
    test('empty rows map to empty', () {
      expect(groupModuleAccessByUser(const []), isEmpty);
    });

    test('groups module ids by user', () {
      expect(
        groupModuleAccessByUser([
          {'user_id': 'u1', 'module_id': 'attendance'},
          {'user_id': 'u1', 'module_id': 'challan'},
          {'user_id': 'u2', 'module_id': 'attendance'},
        ]),
        {
          'u1': {'attendance', 'challan'},
          'u2': {'attendance'},
        },
      );
    });
  });
}
