import 'package:dart_mappable/dart_mappable.dart';

part 'challan_direction.mapper.dart';

/// Outward: goods going to a client. Inward: goods coming back. Each has its
/// own number series per financial year.
@MappableEnum()
enum ChallanDirection {
  outward,
  inward;

  /// "Outward" / "Inward".
  String get label => switch (this) {
    ChallanDirection.outward => 'Outward',
    ChallanDirection.inward => 'Inward',
  };

  /// What the person named on the challan did with the goods.
  String get handledByLabel => switch (this) {
    ChallanDirection.outward => 'Delivered by',
    ChallanDirection.inward => 'Received by',
  };
}
