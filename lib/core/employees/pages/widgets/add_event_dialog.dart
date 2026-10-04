import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/form_dialog.dart';
import '../../../widgets/guarded_save.dart';
import '../../../widgets/typeahead_picker_field.dart';
import '../../models/timeline_entry.dart';
import '../../providers/employee_providers.dart';
import '../../repositories/event_type_repository.dart';

final _dateFormat = DateFormat('d MMM yyyy');

Future<void> showAddEventDialog(
  BuildContext context,
  WidgetRef ref,
  String employeeId, {
  TimelineEntry? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _AddEventDialog(employeeId: employeeId, existing: existing),
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
  late final _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late DateTime _eventDate = widget.existing?.entryDate ?? DateTime.now();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> existingTypeIds) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final typed = slugifyEventType(_typedType);

    var typeId = typed;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        if (!existingTypeIds.contains(typed)) {
          final created = await ref
              .read(eventTypeRepositoryProvider)
              .addDescriptiveType(typed);
          typeId = created.id;
        }
        final note = _noteController.text.isEmpty ? null : _noteController.text;
        if (_isEditing) {
          await ref
              .read(employeeEventRepositoryProvider)
              .updateEvent(
                id: widget.existing!.id,
                eventType: typeId,
                eventDate: _eventDate,
                note: note,
              );
        } else {
          await ref
              .read(employeeEventRepositoryProvider)
              .addEvent(
                employeeId: widget.employeeId,
                eventType: typeId,
                eventDate: _eventDate,
                note: note,
              );
        }
      },
      onSuccess: () {
        ref.invalidate(eventTypesProvider);
        ref.invalidate(employeeTimelineProvider(widget.employeeId));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return FormDialog(
      key: const Key('add-event-dialog'),
      title: _isEditing ? 'Edit event' : 'Add event',
      formKey: _formKey,
      saving: _saving,
      onSave: () {
        final types = eventTypesAsync.value;
        if (types != null) _save(types.map((t) => t.id).toList());
      },
      children: [
        eventTypesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('$error'),
          data: (types) => TypeaheadPickerField(
            options: types.map((t) => t.id).toList(),
            labelText: 'Type',
            helperText: 'Pick one, or type a new name',
            initialValue: widget.existing?.label,
            autofocus: !FormDialog.isCompact(context),
            validator: (value) =>
                slugifyEventType(value ?? '').isEmpty ? 'Choose a type' : null,
            onChanged: (value) => _typedType = value,
          ),
        ),
        DateFormField(
          fieldKey: const Key('event-date-field'),
          label: 'Date',
          value: _eventDate,
          format: _dateFormat.format,
          onChanged: (d) => setState(() => _eventDate = d),
        ),
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
          minLines: 1,
          maxLines: 4,
        ),
      ],
    );
  }
}
