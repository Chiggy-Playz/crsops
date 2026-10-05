import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/repositories/employee_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _employeeRow(String id) => {
  'id': id,
  'name': 'Name $id',
  'color': 0,
  'created_at': '2024-01-01T00:00:00Z',
};

void main() {
  group('employeesWithStatus', () {
    test('gives each employee their status from the status rows', () {
      final employees = employeesWithStatus(
        [_employeeRow('1'), _employeeRow('2')],
        [
          {'employee_id': '1', 'status': 'active'},
          {'employee_id': '2', 'status': 'inactive'},
        ],
      );
      expect(employees.map((e) => e.status), [
        EmploymentStatus.active,
        EmploymentStatus.inactive,
      ]);
    });

    test(
      'an employee with no status row has no status and counts as active',
      () {
        final employees = employeesWithStatus([_employeeRow('1')], const []);
        expect(employees.single.status, isNull);
        expect(employees.single.isInactive, isFalse);
      },
    );
  });
}
