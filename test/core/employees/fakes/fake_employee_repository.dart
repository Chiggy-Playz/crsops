import 'package:crs_ops/core/employees/models/employee.dart';
import 'package:crs_ops/core/employees/repositories/employee_repository.dart';

class FakeEmployeeRepository implements EmployeeRepository {
  FakeEmployeeRepository({
    List<Employee>? seed,
    Map<String, EmploymentStatus>? statusById,
  }) : _employees = List.of(seed ?? const []),
       _statusById = Map.of(statusById ?? const {});

  final List<Employee> _employees;
  final Map<String, EmploymentStatus> _statusById;

  /// Join date passed to [create], by new employee id.
  final Map<String, DateTime> joinedOnById = {};

  Employee _withStatus(Employee e) => e.copyWith(status: _statusById[e.id]);

  @override
  Future<List<Employee>> fetchAll() async =>
      _employees.map(_withStatus).toList();

  @override
  Future<Employee> fetchById(String id) async =>
      _withStatus(_employees.firstWhere((e) => e.id == id));

  @override
  Future<void> create({
    required String name,
    required int color,
    int? salary,
    String? notes,
    required DateTime joinedOn,
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
    joinedOnById[employee.id] = joinedOn;
    _statusById[employee.id] = EmploymentStatus.active;
  }

  @override
  Future<void> update(Employee employee) async {
    final index = _employees.indexWhere((e) => e.id == employee.id);
    _employees[index] = employee;
  }
}
