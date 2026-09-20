import 'package:dart_mappable/dart_mappable.dart';

part 'employee.mapper.dart';

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
  final double? salary;
  @MappableField(key: 'notes')
  final String? notes;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
