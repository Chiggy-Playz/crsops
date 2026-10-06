import '../../core/utils/date_time_format.dart';
import 'models/challan_direction.dart';
import 'models/challan_event.dart';

/// How one history row reads: a title and any detail lines under it.
class HistoryText {
  const HistoryText(this.title, [this.details = const []]);

  final String title;
  final List<String> details;
}

/// Turns a history row into words. [direction] decides whether the person
/// field reads "Delivered by" or "Received by".
HistoryText describeChallanEvent(
  ChallanEvent event,
  ChallanDirection direction,
) {
  final changes = event.changes;
  final note = event.note;
  final noteLines = note == null ? const <String>[] : [note];

  switch (event.eventType) {
    case 'created':
      return HistoryText('Created', noteLines);
    case 'cancelled':
      final details = [
        if (note != null) 'Reason: $note',
        if (changes['return_number'] != null)
          'Goods brought back on inward challan ${changes['return_number']}',
      ];
      return HistoryText('Cancelled', details);
    case 'received':
      final receivedOn = _toOf(changes, 'received_on');
      if (receivedOn == null) return const HistoryText('Marked not received');
      return HistoryText(
        'Signed copy received on '
        '${formatDisplayDate(DateTime.parse(receivedOn as String))}',
      );
    case 'bill_number':
      final billNumber = _toOf(changes, 'bill_number');
      if (billNumber == null) return const HistoryText('Bill number removed');
      return HistoryText('Bill number set to $billNumber');
    case 'digitally_signed':
      final signed = _toOf(changes, 'digitally_signed') == true;
      return HistoryText(
        signed ? 'Marked digitally signed' : 'Marked not digitally signed',
      );
    case 'edited':
      return HistoryText('Edited', [
        for (final entry in changes.entries)
          _describeChange(entry.key, entry.value, direction),
        ...noteLines,
      ]);
    default:
      return HistoryText(event.eventType, noteLines);
  }
}

Object? _toOf(Map<String, dynamic> changes, String field) {
  final change = changes[field];
  if (change is! Map) return null;
  return change['to'];
}

/// "Vehicle: DL1C1234 → DL3C9876", "Items: 3 → 4 lines".
String _describeChange(
  String field,
  Object? change,
  ChallanDirection direction,
) {
  final from = change is Map ? change['from'] : null;
  final to = change is Map ? change['to'] : null;

  if (field == 'items') {
    final fromCount = from is List ? from.length : 0;
    final toCount = to is List ? to.length : 0;
    if (fromCount == toCount) return 'Items changed';
    return 'Items: $fromCount → $toCount lines';
  }

  final String label;
  switch (field) {
    case 'handled_by_name':
      label = direction.handledByLabel;
    case 'vehicle_number':
      label = 'Vehicle';
    case 'declared_value':
      label = 'Value';
    case 'notes':
      label = 'Notes';
    case 'address':
      label = 'Client details';
    default:
      label = field;
  }
  return '$label: ${from ?? 'none'} → ${to ?? 'none'}';
}
