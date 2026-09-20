import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/typeahead_picker_field.dart';
import '../../models/timeline_entry.dart';
import '../../providers/employee_providers.dart';

final _dateFormat = DateFormat('d MMM yyyy');

Future<void> showAddEventDialog(BuildContext context, WidgetRef ref, String employeeId, {TimelineEntry? existing}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AddEventDialog(employeeId: employeeId, existing: existing),
  );
}

class _AddEventDialog extends ConsumerStatefulWidget {
  const _AddEventDialog({required this.employeeId, this.existing});
  final String employeeId;
  final TimelineEntry? existing;

  @override
  ConsumerState<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<_AddEventDialog> {
  late String _typedType = widget.existing?.label ?? '';
  late final _noteController = TextEditingController(text: widget.existing?.note ?? '');
  late DateTime _eventDate = widget.existing?.entryDate ?? DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  Future<void> _save(List<String> existingTypeIds) async {
    final typed = _typedType.trim();
    if (typed.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      var typeId = typed;
      if (!existingTypeIds.contains(typed)) {
        final created = await ref.read(eventTypeRepositoryProvider).addDescriptiveType(typed);
        typeId = created.id;
        ref.invalidate(eventTypesProvider);
      }

      final note = _noteController.text.isEmpty ? null : _noteController.text;
      if (_isEditing) {
        await ref.read(employeeEventRepositoryProvider).updateEvent(
              id: widget.existing!.id,
              eventType: typeId,
              eventDate: _eventDate,
              note: note,
            );
      } else {
        await ref.read(employeeEventRepositoryProvider).addEvent(
              employeeId: widget.employeeId,
              eventType: typeId,
              eventDate: _eventDate,
              note: note,
            );
      }
      ref.invalidate(employeeTimelineProvider(widget.employeeId));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return AlertDialog(
      key: const Key('add-event-dialog'),
      title: Text(_isEditing ? 'Edit event' : 'Add event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          eventTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => TypeaheadPickerField(
              options: types.map((t) => t.id).toList(),
              labelText: 'Type (existing or new)',
              initialValue: widget.existing?.label,
              onChanged: (value) => _typedType = value,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_month)),
            child: InkWell(
              key: const Key('event-date-field'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _eventDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _eventDate = picked);
              },
              child: Text(_dateFormat.format(_eventDate)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || !eventTypesAsync.hasValue
              ? null
              : () => _save(eventTypesAsync.value!.map((t) => t.id).toList()),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
