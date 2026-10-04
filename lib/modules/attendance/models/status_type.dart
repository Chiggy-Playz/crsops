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

/// The order statuses are offered in: the everyday ones first (what gets
/// tapped most), then any custom types alphabetically by label.
const _builtInOrder = ['present', 'absent', 'leave', 'holiday', 'week_off'];

/// Built-ins by their fixed position; anything custom ranks after them.
int statusDisplayRank(String statusId) {
  final i = _builtInOrder.indexOf(statusId);
  return i == -1 ? _builtInOrder.length : i;
}

List<StatusType> inDisplayOrder(Iterable<StatusType> types) {
  return types.toList()..sort((a, b) {
    final byRank = statusDisplayRank(a.id).compareTo(statusDisplayRank(b.id));
    return byRank != 0
        ? byRank
        : a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
}
