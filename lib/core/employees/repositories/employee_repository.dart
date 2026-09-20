import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/employee.dart';

/// Status text from `employee_current_status` rows, or null when the
/// employee has no status row. Pure so the empty→null contract stays unit
/// tested without a Supabase client.
String? currentStatusFromRows(List<Map<String, dynamic>> rows) =>
    rows.isEmpty ? null : rows.first['status'] as String?;

/// Per-employee status map from `employee_current_status` rows. Pure, same
/// reason as above.
Map<String, String> currentStatusMap(List<Map<String, dynamic>> rows) => {
  for (final row in rows) row['employee_id'] as String: row['status'] as String,
};

abstract class EmployeeRepository {
  Future<List<Employee>> fetchAll();
  Future<Employee> fetchById(String id);
  Future<Employee> create({
    required String name,
    required int color,
    double? salary,
    String? notes,
  });
  Future<Employee> update(Employee employee);
  Future<String?> fetchCurrentStatus(String employeeId);
  Future<Map<String, String>> fetchAllCurrentStatuses();
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  SupabaseEmployeeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Employee>> fetchAll() async {
    try {
      final rows = await _client
          .schema('core')
          .from('employees')
          .select()
          .order('name');
      return rows.map(EmployeeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> fetchById(String id) async {
    try {
      final row = await _client
          .schema('core')
          .from('employees')
          .select()
          .eq('id', id)
          .single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> create({
    required String name,
    required int color,
    double? salary,
    String? notes,
  }) async {
    try {
      final row = await _client
          .schema('core')
          .from('employees')
          .insert({
            'name': name,
            'color': color,
            'salary': salary,
            'notes': notes,
          })
          .select()
          .single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> update(Employee employee) async {
    try {
      final row = await _client
          .schema('core')
          .from('employees')
          .update({
            'name': employee.name,
            'color': employee.color,
            'salary': employee.salary,
            'notes': employee.notes,
          })
          .eq('id', employee.id)
          .select()
          .single();
      return EmployeeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<String?> fetchCurrentStatus(String employeeId) async {
    try {
      final rows = await _client
          .schema('core')
          .from('employee_current_status')
          .select('status')
          .eq('employee_id', employeeId);
      return currentStatusFromRows(rows);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Map<String, String>> fetchAllCurrentStatuses() async {
    try {
      final rows = await _client
          .schema('core')
          .from('employee_current_status')
          .select('employee_id, status');
      return currentStatusMap(rows);
    } catch (error) {
      throw translateException(error);
    }
  }
}
