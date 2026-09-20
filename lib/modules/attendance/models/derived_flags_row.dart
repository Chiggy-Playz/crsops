import 'package:dart_mappable/dart_mappable.dart';

part 'derived_flags_row.mapper.dart';

@MappableClass()
class DerivedFlagsRow with DerivedFlagsRowMappable {
  const DerivedFlagsRow({
    required this.employeeId,
    required this.date,
    this.timeIn,
    this.timeOut,
    required this.workedMinutes,
    required this.isLate,
    required this.isEarly,
    required this.overtimeMinutes,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'worked_minutes')
  final int workedMinutes;
  @MappableField(key: 'is_late')
  final bool isLate;
  @MappableField(key: 'is_early')
  final bool isEarly;
  @MappableField(key: 'overtime_minutes')
  final int overtimeMinutes;
}
