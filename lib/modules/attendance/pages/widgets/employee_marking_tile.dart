import 'package:flutter/material.dart';

import '../../../../core/employees/models/employee.dart';
import '../../../../core/widgets/status_metadata.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_type.dart';

typedef StatusPick = ({String statusId, String? note});

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
        currentNote: status?.note,
        isCurrentlyMarked: status?.firstHalfStatus != null,
      ),
    );
    if (result == null) return;
    if (result.statusId.isEmpty) {
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
    final currentStatusId =
        status?.firstHalfStatus == status?.secondHalfStatus ? status?.firstHalfStatus : null;
    final isWeekOff = status?.isWeekOff == true;
    final isUnmarked = status?.firstHalfStatus == null;
    final currentLabel = !isUnmarked
        ? (status!.firstHalfStatus == status!.secondHalfStatus
            ? displayLabel(status!.firstHalfStatus!)
            : '${displayLabel(status!.firstHalfStatus!)} / ${displayLabel(status!.secondHalfStatus ?? '—')}')
        : (isWeekOff ? 'Week off' : null);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          initialsFor(employee.name),
          style: TextStyle(color: contrastingTextColor(color), fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(employee.name),
      subtitle: currentLabel == null
          ? const Text('Unmarked')
          : Text(status?.note?.trim().isNotEmpty == true ? '$currentLabel · ${status!.note}' : currentLabel),
      trailing: busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : OutlinedButton.icon(
              key: Key('mark-status-${employee.id}'),
              onPressed: statusTypes.isEmpty ? null : () => _openStatusPicker(context),
              icon: currentStatusId != null
                  ? Icon(iconFor(_currentIconName(currentStatusId)), size: 18)
                  : isWeekOff
                      ? const Icon(Icons.weekend, size: 18)
                      : const Icon(Icons.add, size: 18),
              label: Text(isUnmarked ? (isWeekOff ? 'Week off' : 'Mark') : currentLabel!),
            ),
    );
  }
}

class _StatusPickerSheet extends StatefulWidget {
  const _StatusPickerSheet({
    required this.employeeName,
    required this.statusTypes,
    required this.currentNote,
    required this.isCurrentlyMarked,
  });

  final String employeeName;
  final List<StatusType> statusTypes;
  final String? currentNote;
  final bool isCurrentlyMarked;

  @override
  State<_StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<_StatusPickerSheet> {
  late final _noteController = TextEditingController(text: widget.currentNote ?? '');

  String? get _note => _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Mark ${widget.employeeName}', style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('mark-status-note-field'),
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            for (final type in widget.statusTypes)
              ListTile(
                leading: Icon(iconFor(type.iconName), color: colorFor(type.colorHex)),
                title: Text(type.label),
                onTap: () => Navigator.of(context).pop((statusId: type.id, note: _note)),
              ),
            if (widget.isCurrentlyMarked) ...[
              const Divider(height: 1),
              ListTile(
                key: const Key('mark-status-unmark'),
                leading: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error),
                title: Text('Unmarked', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => Navigator.of(context).pop((statusId: '', note: null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
