import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';
import '../../../../core/widgets/status_metadata.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_type.dart';
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
    final color = Color(employee.color);
    final iconByStatusId = {
      for (final type in statusTypes)
        if (type.iconName != null) type.id: type.iconName!,
    };
    final currentStatusId = status?.firstHalfStatus == status?.secondHalfStatus
        ? status?.firstHalfStatus
        : null;
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          initialsFor(employee.name),
          style: TextStyle(
            color: contrastingTextColor(color),
            fontWeight: FontWeight.bold,
          ),
        ),
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
          : OutlinedButton.icon(
              key: Key('mark-status-${employee.id}'),
              onPressed: statusTypes.isEmpty
                  ? null
                  : () => _openStatusPicker(context),
              icon: currentStatusId != null
                  ? Icon(iconFor(iconByStatusId[currentStatusId]), size: 18)
                  : isWeekOff
                  ? const Icon(Icons.weekend, size: 18)
                  : const Icon(Icons.add, size: 18),
              label: Text(
                isUnmarked ? (isWeekOff ? 'Week off' : 'Mark') : currentLabel!,
              ),
            ),
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
