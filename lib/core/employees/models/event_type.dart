import 'package:dart_mappable/dart_mappable.dart';

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
  @MappableField(key: 'status_effect')
  final String? statusEffect;
  @MappableField(key: 'icon_name')
  final String? iconName;
  @MappableField(key: 'color_hex')
  final String? colorHex;
  @MappableField(key: 'description')
  final String? description;

  bool get isStructural => statusEffect != null;
}
