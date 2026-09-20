import 'package:dart_mappable/dart_mappable.dart';

part 'timeline_entry.mapper.dart';

@MappableClass()
class TimelineEntry with TimelineEntryMappable {
  const TimelineEntry({
    required this.employeeId,
    required this.entryDate,
    required this.kind,
    required this.label,
    this.note,
  });

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'entry_date')
  final DateTime entryDate;
  @MappableField(key: 'kind')
  final String kind;
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'note')
  final String? note;
}
