import 'package:crs_ops/core/employees/repositories/employee_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('currentStatusFromRows', () {
    test('no rows means no status', () {
      expect(currentStatusFromRows(const []), isNull);
    });

    test('returns the first row status', () {
      expect(
        currentStatusFromRows([
          {'status': 'active'},
        ]),
        'active',
      );
    });
  });

  group('currentStatusMap', () {
    test('empty rows map to empty', () {
      expect(currentStatusMap(const []), isEmpty);
    });

    test('maps each employee to its status', () {
      expect(
        currentStatusMap([
          {'employee_id': '1', 'status': 'active'},
          {'employee_id': '2', 'status': 'inactive'},
        ]),
        {'1': 'active', '2': 'inactive'},
      );
    });
  });
}
