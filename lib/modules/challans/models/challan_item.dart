import 'package:dart_mappable/dart_mappable.dart';

part 'challan_item.mapper.dart';

/// One printed line of a challan.
@MappableClass()
class ChallanItem with ChallanItemMappable {
  const ChallanItem({
    required this.description,
    this.additionalDescription,
    this.serial,
    required this.quantity,
    this.unit,
  });

  @MappableField(key: 'description')
  final String description;

  /// A second line under the description, e.g. the configuration.
  @MappableField(key: 'additional_description')
  final String? additionalDescription;
  @MappableField(key: 'serial')
  final String? serial;
  @MappableField(key: 'quantity')
  final int quantity;

  /// Optional: "SET", "NOS". Printed after the quantity when set.
  @MappableField(key: 'unit')
  final String? unit;

  /// "2 SET", or just "2".
  String get quantityText => unit == null ? '$quantity' : '$quantity $unit';
}
