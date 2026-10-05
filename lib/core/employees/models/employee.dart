import 'package:dart_mappable/dart_mappable.dart';

part 'employee.mapper.dart';

/// Whether someone currently works here, worked out by the database
/// (`core.employee_current_status`) from their latest joined/left event.
@MappableEnum()
enum EmploymentStatus { active, inactive }

@MappableClass()
class Employee with EmployeeMappable {
  const Employee({
    required this.id,
    this.userId,
    required this.name,
    required this.color,
    this.salary,
    this.notes,
    required this.createdAt,
    this.status,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'user_id')
  final String? userId;
  @MappableField(key: 'name')
  final String name;
  @MappableField(key: 'color')
  final int color;
  @MappableField(key: 'salary')
  final int? salary;
  @MappableField(key: 'notes')
  final String? notes;
  @MappableField(key: 'created_at')
  final DateTime createdAt;

  /// Not a column of `employees`: the repository fills it in from
  /// `employee_current_status`. Null when they have no joined/left history.
  @MappableField(key: 'status')
  final EmploymentStatus? status;

  /// No history counts as active, so a new hire never disappears.
  bool get isInactive => status == EmploymentStatus.inactive;
}
