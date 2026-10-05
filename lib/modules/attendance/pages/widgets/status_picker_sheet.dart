import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../../../core/utils/status_metadata.dart';
import '../../models/status_type.dart';

typedef StatusPick = ({
  String? firstHalfStatus,
  String? secondHalfStatus,
  String? timeIn,
  String? timeOut,
  String? note,
});

class StatusPickerSheet extends StatefulWidget {
  const StatusPickerSheet({
    super.key,
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
  State<StatusPickerSheet> createState() => _StatusPickerSheetState();
}

class _StatusPickerSheetState extends State<StatusPickerSheet> {
  late final _noteController = TextEditingController(
    text: widget.currentNote ?? '',
  );
  late TimeOfDay? _timeIn = parseStoredTime(widget.currentTimeIn);
  late TimeOfDay? _timeOut = parseStoredTime(widget.currentTimeOut);

  /// Set the moment a time is picked or cleared: distinguishes "untouched,
  /// still showing the row's stored value" from "user explicitly cleared it
  /// to null", so quick-pick never resurrects a cleared time.
  bool _timesTouched = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String? get _note {
    final text = _noteController.text.trim();
    return text.isEmpty ? null : text;
  }

  String? get _storedTimeIn => _timeIn == null ? null : toStoredTime(_timeIn!);
  String? get _storedTimeOut =>
      _timeOut == null ? null : toStoredTime(_timeOut!);

  /// Quick full-day tap preserves already-entered times rather than
  /// silently wiping them — times are only changed via the advanced section.
  /// Untouched fields pass the stored strings through verbatim; touched
  /// fields (picked or cleared) use the sheet's current values.
  void _pickFullDay(String statusId) => Navigator.of(context).pop((
    firstHalfStatus: statusId,
    secondHalfStatus: statusId,
    timeIn: _timesTouched ? _storedTimeIn : widget.currentTimeIn,
    timeOut: _timesTouched ? _storedTimeOut : widget.currentTimeOut,
    note: _note,
  ));

  /// Halves aren't user-editable (hidden for now): pass through whatever the
  /// row already has. Nulls mean "unmarked" — the repository applies the
  /// presence default, not the UI.
  void _saveTimes() => Navigator.of(context).pop((
    firstHalfStatus: widget.currentFirstHalf,
    secondHalfStatus: widget.currentSecondHalf,
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
      setState(() {
        _timesTouched = true;
        if (isIn) {
          _timeIn = picked;
        } else {
          _timeOut = picked;
        }
      });
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
              onPressed: () => setState(() {
                _timesTouched = true;
                if (isIn) {
                  _timeIn = null;
                } else {
                  _timeOut = null;
                }
              }),
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
                    color: context.customColor(colorFor(type.colorHex)).color,
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
