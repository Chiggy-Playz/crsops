import 'package:dart_mappable/dart_mappable.dart';

part 'gap_row.mapper.dart';

@MappableClass()
class GapRow with GapRowMappable {
  const GapRow({required this.employeeId, required this.date});

  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'date')
  final DateTime date;
}
