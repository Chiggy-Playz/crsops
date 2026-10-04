import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';
import '../../../../core/widgets/status_metadata.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_type.dart';
import 'status_badge.dart';
import 'status_picker_sheet.dart';

class EmployeeMarkingTile extends StatelessWidget {
  const EmployeeMarkingTile({
    super.key,
    required this.employee,
    required this.status,
    required this.statusTypes,
    required this.busy,
    required this.onMarkStatus,
    required this.onUnmark,
  });

  final Employee employee;
  final EffectiveStatusRow? status;
  final List<StatusType> statusTypes;
  final bool busy;
  final ValueChanged<StatusPick> onMarkStatus;
  final VoidCallback onUnmark;

  Future<void> _openStatusPicker(BuildContext context) async {
    final result = await showModalBottomSheet<StatusPick?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatusPickerSheet(
        employeeName: employee.name,
        statusTypes: statusTypes,
        currentFirstHalf: status?.firstHalfStatus,
        currentSecondHalf: status?.secondHalfStatus,
        currentTimeIn: status?.timeIn,
        currentTimeOut: status?.timeOut,
        currentNote: status?.note,
        isCurrentlyMarked: status?.firstHalfStatus != null,
      ),
    );
    if (result == null) return;
    // All-null means "nothing was entered" (the sheet's Unmark entry pops
    // exactly this) — anything else, times/note included, is a marking, with
    // null halves resolved to the presence default by the repository.
    final isEmpty =
        result.firstHalfStatus == null &&
        result.secondHalfStatus == null &&
        result.timeIn == null &&
        result.timeOut == null &&
        result.note == null;
    if (isEmpty) {
      onUnmark();
    } else {
      onMarkStatus(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeById = {for (final type in statusTypes) type.id: type};
    final isWeekOff = status?.isWeekOff == true;
    final isUnmarked = status?.firstHalfStatus == null;
    final currentLabel = !isUnmarked
        ? (status!.firstHalfStatus == status!.secondHalfStatus
              ? displayLabel(status!.firstHalfStatus!)
              : '${displayLabel(status!.firstHalfStatus!)} / ${displayLabel(status!.secondHalfStatus ?? '—')}')
        : (isWeekOff ? 'Week off' : null);

    final hasTimes = status?.timeIn != null || status?.timeOut != null;
    final timeLabel = hasTimes
        ? _formatStoredTimeRange(context, status?.timeIn, status?.timeOut)
        : null;
    final note = status?.note?.trim();
    final subtitleParts = [
      ?currentLabel,
      ?timeLabel,
      if (note?.isNotEmpty == true) note!,
    ];

    // An unmarked week-off day shows as Week off, same as its label.
    final weekOffType = isUnmarked && isWeekOff ? typeById['week_off'] : null;

    // The whole row opens the status sheet — the badge already shows the
    // status, so a separate button only repeated it.
    return ListTile(
      key: Key('mark-status-${employee.id}'),
      enabled: !busy && statusTypes.isNotEmpty,
      onTap: () => _openStatusPicker(context),
      leading: StatusBadge(
        firstHalf: typeById[status?.firstHalfStatus] ?? weekOffType,
        secondHalf: typeById[status?.secondHalfStatus] ?? weekOffType,
      ),
      title: Text(employee.name),
      subtitle: subtitleParts.isEmpty
          ? const Text('Unmarked')
          : Text(subtitleParts.join(' · ')),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}

/// Stored as "HH:mm" on write; Postgres `time` may read back as "HH:mm:ss" —
/// both parse. Display is always locale-aware via MaterialLocalizations.
String _formatStoredTime(BuildContext context, String? stored) {
  final parsed = parseStoredTime(stored);
  if (parsed == null) return stored ?? '--:--';
  return MaterialLocalizations.of(context).formatTimeOfDay(parsed);
}

/// Tile subtitle time fragment: a range when both sides exist, just the
/// set side ("in …" / "out …") for a half-entered pair, null when neither.
String? _formatStoredTimeRange(
  BuildContext context,
  String? timeIn,
  String? timeOut,
) {
  if (timeIn == null && timeOut == null) return null;
  if (timeIn == null) return 'out ${_formatStoredTime(context, timeOut)}';
  if (timeOut == null) return 'in ${_formatStoredTime(context, timeIn)}';
  return '${_formatStoredTime(context, timeIn)}–${_formatStoredTime(context, timeOut)}';
}
