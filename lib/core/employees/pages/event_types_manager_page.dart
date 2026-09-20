import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/color_swatch_picker.dart';
import '../../widgets/status_metadata.dart';
import '../models/event_type.dart';
import '../providers/employee_providers.dart';

const _kIconNames = ['check', 'close', 'event_busy', 'beach_access', 'weekend'];

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
              title: Text(displayLabel(type.id)),
              subtitle: type.isStructural ? Text('Structural: ${displayLabel(type.statusEffect!)}') : null,
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
  late String? _iconName = widget.type.iconName;
  late String? _colorHex = widget.type.colorHex;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(eventTypeRepositoryProvider).updateDisplay(
            widget.type.id,
            iconName: _iconName,
            colorHex: _colorHex,
          );
      ref.invalidate(eventTypesProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('event-type-edit-dialog'),
      title: Text('Edit ${displayLabel(widget.type.id)}'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownMenu<String>(
              initialSelection: _iconName,
              expandedInsets: EdgeInsets.zero,
              hintText: 'Icon',
              dropdownMenuEntries: _kIconNames
                  .map((name) => DropdownMenuEntry(value: name, label: name, leadingIcon: Icon(iconFor(name))))
                  .toList(),
              onSelected: (value) => setState(() => _iconName = value),
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            const SizedBox(height: 8),
            ColorSwatchPicker(
              selectedHex: _colorHex,
              onChanged: (hex) => setState(() => _colorHex = hex),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
