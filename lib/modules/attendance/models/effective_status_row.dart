import 'package:dart_mappable/dart_mappable.dart';

part 'effective_status_row.mapper.dart';

@MappableClass()
class EffectiveStatusRow with EffectiveStatusRowMappable {
  const EffectiveStatusRow({
    required this.employeeId,
    required this.date,
    this.firstHalfStatus,
    this.secondHalfStatus,
    required this.isExplicit,
    required this.isWeekOff,
    this.timeIn,
    this.timeOut,
    this.note,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
  @MappableField(key: 'first_half_status')
  final String? firstHalfStatus;
  @MappableField(key: 'second_half_status')
  final String? secondHalfStatus;
  @MappableField(key: 'is_explicit')
  final bool isExplicit;
  @MappableField(key: 'is_week_off')
  final bool isWeekOff;
  @MappableField(key: 'time_in')
  final String? timeIn;
  @MappableField(key: 'time_out')
  final String? timeOut;
  @MappableField(key: 'note')
  final String? note;
}
