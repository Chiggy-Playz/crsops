import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../../errors/exception_translator.dart';
import '../../utils/status_metadata.dart';
import '../../utils/date_time_format.dart';
import '../models/employee.dart';

/// Employee rows with each one's `status` filled in from
/// `employee_current_status` rows (`employee_id`, `status`). Pure so the
/// merge stays unit tested without a Supabase client.
List<Employee> employeesWithStatus(
  List<Map<String, dynamic>> employeeRows,
  List<Map<String, dynamic>> statusRows,
) {
  final statusById = {
    for (final row in statusRows)
      row['employee_id'] as String: row['status'] as String,
  };
  return [
    for (final row in employeeRows)
      EmployeeMapper.fromMap({...row, 'status': statusById[row['id']]}),
  ];
}

abstract class EmployeeRepository {
  /// Everyone, by name, each with their current [Employee.status].
  Future<List<Employee>> fetchAll();
  Future<Employee> fetchById(String id);
  Future<void> create({
    required String name,
    required int color,
    int? salary,
    String? notes,
    required DateTime joinedOn,
  });
  Future<void> update(Employee employee);
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  SupabaseEmployeeRepository(this._client);
  final SupabaseClient _client;

  // Status isn't a column of `employees` (the database derives it from
  // their events), so it's fetched alongside and merged in. Future.wait
  // sends both requests at once and rethrows the first one's error as is.

  @override
  Future<List<Employee>> fetchAll() async {
    try {
      final results = await Future.wait([
        _client
            .schema('core')
            .from('employees')
            .select()
            .order('name', ascending: true),
        _client
            .schema('core')
            .from('employee_current_status')
            .select('employee_id, status'),
      ]);
      return employeesWithStatus(results[0], results[1]);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> fetchById(String id) async {
    try {
      final results = await Future.wait([
        _client.schema('core').from('employees').select().eq('id', id),
        _client
            .schema('core')
            .from('employee_current_status')
            .select('employee_id, status')
            .eq('employee_id', id),
      ]);
      if (results[0].isEmpty) {
        throw const DataException(
          'That no longer exists. It may have been deleted.',
        );
      }
      return employeesWithStatus(results[0], results[1]).single;
    } catch (error) {
      throw translateException(error);
    }
  }

  /// Creates the employee and their "joined" event together in one database
  /// transaction (the `core.create_employee` function), so a failure can't
  /// leave an employee with no history.
  @override
  Future<void> create({
    required String name,
    required int color,
    int? salary,
    String? notes,
    required DateTime joinedOn,
  }) async {
    try {
      await _client
          .schema('core')
          .rpc(
            'create_employee',
            params: {
              'p_name': titleCase(name),
              'p_color': color,
              'p_salary': salary,
              'p_notes': notes,
              'p_joined_on': dateOnly(joinedOn),
            },
          );
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> update(Employee employee) async {
    try {
      await _client
          .schema('core')
          .from('employees')
          .update({
            'name': titleCase(employee.name),
            'color': employee.color,
            'salary': employee.salary,
            'notes': employee.notes,
          })
          .eq('id', employee.id);
    } catch (error) {
      throw translateException(error);
    }
  }
}
