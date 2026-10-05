import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/widgets/color_swatch_picker.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/guarded_save.dart';
import '../../../core/widgets/status_metadata.dart';
import '../providers/attendance_providers.dart';
import 'widgets/status_badge.dart';

class StatusTypesManagerPage extends ConsumerWidget {
  const StatusTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(statusTypesProvider);

    return Scaffold(
      appBar: PaneAppBar(
        title: 'Attendance status types',
        parentLocation: '/settings',
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return ListTile(
              leading: StatusBadge(firstHalf: type, secondHalf: type),
              title: Text(type.label),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFormDialog<void>(
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

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _idController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(statusTypeRepositoryProvider)
          .add(
            id: _idController.text.trim(),
            label: _labelController.text.trim(),
            iconName: _iconName,
            colorHex: _colorHex,
          ),
      onSuccess: () {
        ref.invalidate(statusTypesProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? value, String what) =>
        (value ?? '').trim().isEmpty ? 'Enter $what' : null;

    return FormDialog(
      title: 'New status type',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _labelController,
          autofocus: !FormDialog.isCompact(context),
          decoration: const InputDecoration(
            labelText: 'Label',
            helperText: 'Shown in the app, e.g. Sick leave',
          ),
          validator: (v) => required(v, 'a label'),
        ),
        TextFormField(
          controller: _idController,
          decoration: const InputDecoration(
            labelText: 'Id',
            helperText:
                'Stored key, lowercase with underscores, e.g. sick_leave',
          ),
          validator: (v) => required(v, 'an id'),
        ),
        DropdownMenuFormField<String>(
          expandedInsets: EdgeInsets.zero,
          label: const Text('Icon'),
          dropdownMenuEntries: knownIconNames
              .map(
                (name) => DropdownMenuEntry(
                  value: name,
                  label: displayLabel(name),
                  leadingIcon: Icon(iconFor(name)),
                ),
              )
              .toList(),
          onSelected: (value) => setState(() => _iconName = value),
        ),
        LabelledFieldBox(
          label: 'Color',
          child: ColorSwatchPicker(
            selectedHex: _colorHex,
            onChanged: (hex) => setState(() => _colorHex = hex),
          ),
        ),
      ],
    );
  }
}
