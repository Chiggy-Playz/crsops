import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_providers.dart';

Future<void> showAddEventDialog(BuildContext context, WidgetRef ref, String employeeId) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AddEventDialog(employeeId: employeeId),
  );
}

class _AddEventDialog extends ConsumerStatefulWidget {
  const _AddEventDialog({required this.employeeId});
  final String employeeId;

  @override
  ConsumerState<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<_AddEventDialog> {
  String? _selectedType;
  final _newTypeController = TextEditingController();
  final _noteController = TextEditingController();
  bool _creatingNewType = false;

  @override
  Widget build(BuildContext context) {
    final eventTypesAsync = ref.watch(eventTypesProvider);

    return AlertDialog(
      key: const Key('add-event-dialog'),
      title: const Text('Add event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          eventTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => DropdownButton<String>(
              value: _selectedType,
              hint: const Text('Choose a type'),
              items: [
                ...types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.id))),
                const DropdownMenuItem(value: '__new__', child: Text('+ New type')),
              ],
              onChanged: (value) => setState(() {
                _creatingNewType = value == '__new__';
                _selectedType = value;
              }),
            ),
          ),
          if (_creatingNewType)
            TextField(
              controller: _newTypeController,
              decoration: const InputDecoration(labelText: 'New type name'),
            ),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            var typeId = _selectedType;
            if (_creatingNewType) {
              final created =
                  await ref.read(eventTypeRepositoryProvider).addDescriptiveType(_newTypeController.text);
              typeId = created.id;
              ref.invalidate(eventTypesProvider);
            }
            if (typeId == null || typeId == '__new__') return;

            await ref.read(employeeEventRepositoryProvider).addEvent(
                  employeeId: widget.employeeId,
                  eventType: typeId,
                  eventDate: DateTime.now(),
                  note: _noteController.text.isEmpty ? null : _noteController.text,
                );
            ref.invalidate(employeeTimelineProvider(widget.employeeId));
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
