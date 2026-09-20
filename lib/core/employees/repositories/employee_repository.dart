import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> fetchAll();
  Future<Employee> fetchById(String id);
  Future<Employee> create({required String name, required int color, double? salary, String? notes});
  Future<Employee> update(Employee employee);
  Future<String?> fetchCurrentStatus(String employeeId);
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  SupabaseEmployeeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Employee>> fetchAll() async {
    try {
      final rows = await _client.schema('core').from('employees').select().order('name');
      return rows.map(EmployeeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Employee> fetchById(String id) async {
    try {
      final row = await _client.schema('core').from('employees').select().eq('id', id).single();
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
          .insert({'name': name, 'color': color, 'salary': salary, 'notes': notes})
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
      if (rows.isEmpty) return null;
      return rows.first['status'] as String?;
    } catch (error) {
      throw translateException(error);
    }
  }
}
