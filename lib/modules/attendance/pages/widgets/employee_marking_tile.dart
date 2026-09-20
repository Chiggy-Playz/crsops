import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';
import '../../../../core/widgets/status_metadata.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_type.dart';

typedef StatusPick = ({
  String? firstHalfStatus,
  String? secondHalfStatus,
  String? timeIn,
  String? timeOut,
  String? note,
});

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
      builder: (context) => _StatusPickerSheet(
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
    if (result.firstHalfStatus == null && result.secondHalfStatus == null) {
      onUnmark();
    } else {
      onMarkStatus(result);
    }
  }

  String? _currentIconName(String? currentStatusId) {
    if (currentStatusId == null) return null;
    for (final type in statusTypes) {
      if (type.id == currentStatusId) return type.iconName;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(employee.color);
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
        ? '${_formatStoredTime(context, status?.timeIn)}–${_formatStoredTime(context, status?.timeOut)}'
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
                  ? Icon(iconFor(_currentIconName(currentStatusId)), size: 18)
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
  final parsed = _parseStoredTime(stored);
  if (parsed == null) return stored ?? '--:--';
  return MaterialLocalizations.of(context).formatTimeOfDay(parsed);
}

TimeOfDay? _parseStoredTime(String? stored) {
  if (stored == null) return null;
  final parts = stored.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _toStoredTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

class _StatusPickerSheet extends StatefulWidget {
  const _StatusPickerSheet({
    required this.employeeName,
    required this.statusTypes,
    required this.currentFirstHalf,
    required this.currentSecondHalf,
    required this.currentTimeIn,
    required this.currentTimeOut,
    required this.currentNote,
    required this.isCurrentlyMarked,
  });

  final String employeeName;
  final List<StatusType> statusTypes;
  final String? currentFirstHalf;
  final String? currentSecondHalf;
  final String? currentTimeIn;
  final String? currentTimeOut;
  final String? currentNote;
  final bool isCurrentlyMarked;

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  late final _noteController = TextEditingController(
    text: widget.currentNote ?? '',
  );
  late TimeOfDay? _timeIn = _parseStoredTime(widget.currentTimeIn);
  late TimeOfDay? _timeOut = _parseStoredTime(widget.currentTimeOut);

  String? get _note =>
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
  String? get _storedTimeIn => _timeIn == null ? null : _toStoredTime(_timeIn!);
  String? get _storedTimeOut =>
      _timeOut == null ? null : _toStoredTime(_timeOut!);

  /// Quick full-day tap preserves any already-entered times rather than
  /// silently wiping them — times are only changed via the advanced section.
  void _pickFullDay(String statusId) => Navigator.of(context).pop((
    firstHalfStatus: statusId,
    secondHalfStatus: statusId,
    timeIn: _storedTimeIn ?? widget.currentTimeIn,
    timeOut: _storedTimeOut ?? widget.currentTimeOut,
    note: _note,
  ));

  /// Halves aren't user-editable (hidden for now): keep whatever the row
  /// already has, defaulting an unmarked day to full-day present — entering
  /// times implies presence.
  void _saveTimes() => Navigator.of(context).pop((
    firstHalfStatus: widget.currentFirstHalf ?? 'present',
    secondHalfStatus: widget.currentSecondHalf ?? 'present',
    timeIn: _storedTimeIn,
    timeOut: _storedTimeOut,
    note: _note,
  ));
  Future<void> _pickTime({required bool isIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isIn ? _timeIn : _timeOut) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => isIn ? _timeIn = picked : _timeOut = picked);
    }
  }

  Widget _timeRow({
    required String label,
    required Key pickerKey,
    required Key clearKey,
    required TimeOfDay? value,
    required bool isIn,
  }) {
    final localizations = MaterialLocalizations.of(context);
    return ListTile(
      key: pickerKey,
      leading: const Icon(Icons.schedule),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value == null ? 'Not set' : localizations.formatTimeOfDay(value),
          ),
          if (value != null)
            IconButton(
              key: clearKey,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear $label',
              onPressed: () =>
                  setState(() => isIn ? _timeIn = null : _timeOut = null),
            ),
        ],
      ),
      onTap: () => _pickTime(isIn: isIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        // Scrollable: expanding "Time in / out" on a small screen
        // would otherwise overflow the sheet.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Mark ${widget.employeeName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const Key('mark-status-note-field'),
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              for (final type in widget.statusTypes)
                ListTile(
                  leading: Icon(
                    iconFor(type.iconName),
                    color: colorFor(type.colorHex),
                  ),
                  title: Text(type.label),
                  onTap: () => _pickFullDay(type.id),
                ),
              const Divider(height: 1),
              ExpansionTile(
                key: const Key('mark-status-advanced'),
                leading: const Icon(Icons.schedule),
                title: const Text('Time in / out'),
                children: [
                  _timeRow(
                    label: 'Time in',
                    pickerKey: const Key('mark-status-time-in'),
                    clearKey: const Key('mark-status-time-in-clear'),
                    value: _timeIn,
                    isIn: true,
                  ),
                  _timeRow(
                    label: 'Time out',
                    pickerKey: const Key('mark-status-time-out'),
                    clearKey: const Key('mark-status-time-out-clear'),
                    value: _timeOut,
                    isIn: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: FilledButton(
                      key: const Key('mark-status-save-times'),
                      onPressed: _saveTimes,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              if (widget.isCurrentlyMarked) ...[
                const Divider(height: 1),
                ListTile(
                  key: const Key('mark-status-unmark'),
                  leading: Icon(
                    Icons.remove_circle_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Unmarked',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop((
                    firstHalfStatus: null,
                    secondHalfStatus: null,
                    timeIn: null,
                    timeOut: null,
                    note: null,
                  )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
