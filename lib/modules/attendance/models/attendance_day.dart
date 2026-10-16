import 'package:dart_mappable/dart_mappable.dart';

part 'attendance_day.mapper.dart';

@MappableClass()
class AttendanceDay with AttendanceDayMappable {
  const AttendanceDay({
    this.id,
    required this.employeeId,
    required this.date,
    this.status,
    this.timeIn,
    this.timeOut,
    this.note,
  });

  @MappableField(key: 'id')
  final String? id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'status')
  final String? status;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'note')
  final String? note;
}
