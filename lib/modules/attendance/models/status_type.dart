import 'package:dart_mappable/dart_mappable.dart';

import 'status_ids.dart';

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

/// Built-ins by their fixed position ([StatusIds.builtInOrder]); anything
/// custom ranks after them.
int statusDisplayRank(String statusId) {
  final i = StatusIds.builtInOrder.indexOf(statusId);
  return i == -1 ? StatusIds.builtInOrder.length : i;
}

/// Built-ins first, then custom types alphabetically by label.
List<StatusType> inDisplayOrder(Iterable<StatusType> types) {
  return types.toList()..sort((a, b) {
    final byRank = statusDisplayRank(a.id).compareTo(statusDisplayRank(b.id));
    return byRank != 0
        ? byRank
        : a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
}
