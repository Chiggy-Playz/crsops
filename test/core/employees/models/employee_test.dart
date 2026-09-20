import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Employee round-trips through JSON shapes matching Postgres output', () {
    final json = {
      'id': '11111111-1111-1111-1111-111111111111',
      'user_id': null,
      'name': 'Ramesh',
      'color': 4283215696,
      'salary': 25000.0,
      'notes': null,
      'created_at': '2024-01-10T00:00:00.000Z',
    };

    final employee = EmployeeMapper.fromMap(json);

    expect(employee.id, '11111111-1111-1111-1111-111111111111');
    expect(employee.userId, isNull);
    expect(employee.name, 'Ramesh');
    expect(employee.color, 4283215696);
    expect(employee.salary, 25000.0);
    expect(employee.createdAt, DateTime.parse('2024-01-10T00:00:00.000Z'));
  });
}
