import 'package:dart_mappable/dart_mappable.dart';

part 'timeline_entry.mapper.dart';

/// Which table a `core.employee_timeline` row came from.
@MappableEnum()
enum TimelineKind {
  /// `employee_events`: joined, left, raise, …
  event,

  /// `employee_ledger_entries`: a payment.
  ledger,
}

@MappableClass()
class TimelineEntry with TimelineEntryMappable {
  const TimelineEntry({
    required this.id,
    required this.employeeId,
    required this.entryDate,
    required this.kind,
    required this.label,
    this.note,
    this.amount,
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'employee_id')
  final String employeeId;
  @MappableField(key: 'entry_date')
  final DateTime entryDate;
  @MappableField(key: 'kind')
  final TimelineKind kind;
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'note')
  final String? note;
  @MappableField(key: 'amount')
  final double? amount;

  bool get isPayment => kind == TimelineKind.ledger;
}
