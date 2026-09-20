import 'package:dart_mappable/dart_mappable.dart';

part 'shift_defaults.mapper.dart';

@MappableClass()
class ShiftDefaults with ShiftDefaultsMappable {
  const ShiftDefaults({
    required this.id,
    required this.effectiveFrom,
    required this.defaultStart,
    required this.defaultEnd,
    required this.weekOffDays,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'effective_from')
  final DateTime effectiveFrom;
  @MappableField(key: 'default_start')
  final String defaultStart;
  @MappableField(key: 'default_end')
  final String defaultEnd;
  @MappableField(key: 'week_off_days')
  final List<int> weekOffDays;
}
