import 'package:dart_mappable/dart_mappable.dart';

part 'employee_event.mapper.dart';

@MappableClass()
class EmployeeEvent with EmployeeEventMappable {
  const EmployeeEvent({
    required this.id,
    required this.employeeId,
    required this.eventType,
    required this.eventDate,
    this.note,
    this.createdBy,
    required this.createdAt,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'event_type')
  final String eventType;
  @MappableField(key: 'event_date')
  final DateTime eventDate;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'created_by')
  final String? createdBy;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
}
