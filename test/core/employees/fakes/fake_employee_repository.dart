import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/repositories/employee_repository.dart';

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    List<Employee>? seed,
    Map<String, String>? statusById,
  }) : _employees = List.of(seed ?? const []),
       _statusById = Map.of(statusById ?? const {});

  final List<Employee> _employees;
  final Map<String, String> _statusById;

  @override
  Future<List<Employee>> fetchAll() async => List.of(_employees);

  @override
  Future<Employee> fetchById(String id) async =>
      _employees.firstWhere((e) => e.id == id);

  @override
  Future<Employee> create({
    required String name,
    required int color,
    double? salary,
    String? notes,
  }) async {
    final employee = Employee(
      id: 'fake-${_employees.length + 1}',
      name: name,
      color: color,
      salary: salary,
      notes: notes,
      createdAt: DateTime(2024, 1, 1),
    );
    _employees.add(employee);
    return employee;
  }

  @override
  Future<Employee> update(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    _employees[index] = employee;
    return employee;
  }

  @override
  Future<String?> fetchCurrentStatus(String employeeId) async =>
      _statusById[employeeId];

  @override
  Future<Map<String, String>> fetchAllCurrentStatuses() async =>
      Map.of(_statusById);
}
