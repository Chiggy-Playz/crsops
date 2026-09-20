import 'package:dart_mappable/dart_mappable.dart';

part 'status_type.mapper.dart';

@MappableClass()
class StatusType with StatusTypeMappable {
  const StatusType({
    required this.id,
    required this.label,
    this.iconName,
    this.colorHex,
    this.description,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'icon_name')
  final String? iconName;
  @MappableField(key: 'color_hex')
  final String? colorHex;
  @MappableField(key: 'description')
  final String? description;
}
