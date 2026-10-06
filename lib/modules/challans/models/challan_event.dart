import 'package:dart_mappable/dart_mappable.dart';

part 'challan_event.mapper.dart';

/// One row of a challan's history, from `challans.challan_history`.
@MappableClass()
class ChallanEvent with ChallanEventMappable {
  const ChallanEvent({
    required this.id,
    required this.challanId,
    required this.eventType,
    this.changes = const {},
    this.note,
    required this.createdAt,
    this.createdByEmail,
  });

  @MappableField(key: 'id')
  final int id;
  @MappableField(key: 'challan_id')
  final String challanId;

  /// created, edited, cancelled, received, bill_number, digitally_signed.
  @MappableField(key: 'event_type')
  final String eventType;

  /// What changed, as `{"field": {"from": …, "to": …}}`.
  @MappableField(key: 'changes')
  final Map<String, dynamic> changes;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
  @MappableField(key: 'created_by_email')
  final String? createdByEmail;
}
