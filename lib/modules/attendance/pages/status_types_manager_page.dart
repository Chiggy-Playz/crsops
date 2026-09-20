import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/color_swatch_picker.dart';
import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';

const _kIconNames = ['check', 'close', 'event_busy', 'beach_access', 'weekend'];

class StatusTypesManagerPage extends ConsumerWidget {
  const StatusTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(statusTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance status types')),
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
              title: Text(type.label),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const _AddStatusTypeDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddStatusTypeDialog extends ConsumerStatefulWidget {
  const _AddStatusTypeDialog();

  @override
  ConsumerState<_AddStatusTypeDialog> createState() =>
      _AddStatusTypeDialogState();
}

class _AddStatusTypeDialogState extends ConsumerState<_AddStatusTypeDialog> {
  final _idController = TextEditingController();
  final _labelController = TextEditingController();
  String? _iconName;
  String? _colorHex;
  bool _saving = false;

  bool get _canSave =>
      !_saving &&
      _idController.text.trim().isNotEmpty &&
      _labelController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(statusTypeRepositoryProvider)
          .add(
            id: _idController.text.trim(),
            label: _labelController.text.trim(),
            iconName: _iconName,
            colorHex: _colorHex,
          );
      ref.invalidate(statusTypesProvider);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New status type'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Id (e.g. leave_sick)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Sick leave)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              hintText: 'Icon',
              dropdownMenuEntries: _kIconNames
                  .map(
                    (name) => DropdownMenuEntry(
                      value: name,
                      label: name,
                      leadingIcon: Icon(iconFor(name)),
                    ),
                  )
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
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
