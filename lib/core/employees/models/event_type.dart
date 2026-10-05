import 'package:dart_mappable/dart_mappable.dart';

import 'employee.dart';

part 'event_type.mapper.dart';

@MappableClass()
class EventType with EventTypeMappable {
  const EventType({
    required this.id,
    this.statusEffect,
    this.iconName,
    this.colorHex,
    this.description,
  });

  @MappableField(key: 'id')
  final String id;

  /// What recording this event does to the employee's status (joined →
  /// active, left → inactive). Null for ordinary events like a raise.
  @MappableField(key: 'status_effect')
  final EmploymentStatus? statusEffect;
  @MappableField(key: 'icon_name')
  final String? iconName;
  @MappableField(key: 'color_hex')
  final String? colorHex;
  @MappableField(key: 'description')
  final String? description;

  bool get isStructural => statusEffect != null;
}
