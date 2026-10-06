import 'package:flutter/material.dart';

import '../../widgets/inset_list_tile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/two_pane_layout.dart';
import '../../settings/routes.dart';
import '../../utils/status_metadata.dart';
import '../../widgets/color_swatch_picker.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../../widgets/labelled_field_box.dart';
import '../models/event_type.dart';
import '../providers/employee_providers.dart';

class EventTypesManagerPage extends ConsumerWidget {
  const EventTypesManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(eventTypesProvider);

    return Scaffold(
      appBar: PaneAppBar(
        title: 'Event types',
        parentLocation: const SettingsRoute().location,
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (types) => ListView.builder(
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            return InsetListTile(
              leading: CircleAvatar(
                backgroundColor: colorFor(type.colorHex),
                child: Icon(iconFor(type.iconName), color: Colors.white),
              ),
              title: Text(displayLabel(type.id)),
              subtitle: type.isStructural
                  ? Text('Structural: ${displayLabel(type.statusEffect!.name)}')
                  : null,
              onTap: () => showFormDialog<void>(
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
  ConsumerState<_EditEventTypeDialog> createState() =>
      _EditEventTypeDialogState();
}

class _EditEventTypeDialogState extends ConsumerState<_EditEventTypeDialog> {
  late String? _iconName = widget.type.iconName;
  late String? _colorHex = widget.type.colorHex;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _save() async {
    if (_saving) return;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(eventTypeRepositoryProvider)
          .updateDisplay(
            widget.type.id,
            iconName: _iconName,
            colorHex: _colorHex,
          ),
      onSuccess: () {
        ref.invalidate(eventTypesProvider);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      key: const Key('event-type-edit-dialog'),
      title: 'Edit ${displayLabel(widget.type.id)}',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        DropdownMenuFormField<String>(
          initialSelection: _iconName,
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
