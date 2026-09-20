import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/status_metadata.dart';
import '../models/event_type.dart';
import '../providers/employee_providers.dart';

class EventTypesManagerPage extends ConsumerWidget {
  const EventTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Event types')),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(type.colorHex),
                child: Icon(iconFor(type.iconName), color: Colors.white),
              ),
              title: Text(type.id),
              subtitle: type.isStructural ? Text('Structural: ${type.statusEffect}') : null,
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => _EditEventTypeDialog(type: type),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EditEventTypeDialog extends ConsumerStatefulWidget {
  const _EditEventTypeDialog({required this.type});
  final EventType type;

  @override
  ConsumerState<_EditEventTypeDialog> createState() => _EditEventTypeDialogState();
}

class _EditEventTypeDialogState extends ConsumerState<_EditEventTypeDialog> {
  late final _colorController = TextEditingController(text: widget.type.colorHex ?? '');
  late String? _iconName = widget.type.iconName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('event-type-edit-dialog'),
      title: Text('Edit ${widget.type.id}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _iconName,
            hint: const Text('Icon'),
            items: const ['check', 'close', 'event_busy', 'beach_access', 'weekend']
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (value) => setState(() => _iconName = value),
          ),
          TextField(controller: _colorController, decoration: const InputDecoration(labelText: 'Color hex (#RRGGBB)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await ref.read(eventTypeRepositoryProvider).updateDisplay(
                  widget.type.id,
                  iconName: _iconName,
                  colorHex: _colorController.text.isEmpty ? null : _colorController.text,
                );
            ref.invalidate(eventTypesProvider);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
