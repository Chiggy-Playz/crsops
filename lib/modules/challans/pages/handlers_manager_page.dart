import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/settings/routes.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_dialog.dart';
import '../../../core/widgets/guarded_save.dart';
import '../../../core/widgets/inset_list_tile.dart';
import '../providers/challan_providers.dart';
import '../repositories/challan_repository.dart';

/// Settings page for the people added under "Delivered by" / "Received by"
/// who aren't employees (employees are managed in the Employees module).
/// Renaming or removing one only changes the list: challans already made keep
/// the name they were printed with.
class HandlersManagerPage extends ConsumerWidget {
  const HandlersManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choicesAsync = ref.watch(handlerChoicesProvider);

    return Scaffold(
      appBar: PaneAppBar(
        title: 'Delivered / received by',
        parentLocation: const SettingsRoute().location,
      ),
      body: choicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (choices) {
          final custom = [
            for (final choice in choices)
              if (!choice.isEmployee) choice,
          ];
          if (custom.isEmpty) {
            return const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No saved names yet',
              message:
                  'A name typed under Delivered by or Received by that is not '
                  'an employee is saved here for next time.',
            );
          }
          return ListView(
            children: [
              for (final handler in custom)
                InsetListTile(
                  title: Text(handler.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rename',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => showFormDialog<void>(
                          context: context,
                          builder: (context) =>
                              _RenameHandlerDialog(handler: handler),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(context, ref, handler),
                      ),
                    ],
                  ),
                  onTap: () => showFormDialog<void>(
                    context: context,
                    builder: (context) =>
                        _RenameHandlerDialog(handler: handler),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    HandlerChoice handler,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove ${handler.name}?',
      message:
          'It leaves the list. Challans already made keep the name as '
          'printed.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (!confirmed) return;
    final removed = await runGuardedAction(
      () => ref.read(challanRepositoryProvider).deleteCustomHandler(handler.id),
    );
    if (removed) ref.read(challansRevisionProvider.notifier).bump();
  }
}

class _RenameHandlerDialog extends ConsumerStatefulWidget {
  const _RenameHandlerDialog({required this.handler});
  final HandlerChoice handler;

  @override
  ConsumerState<_RenameHandlerDialog> createState() =>
      _RenameHandlerDialogState();
}

class _RenameHandlerDialogState extends ConsumerState<_RenameHandlerDialog> {
  late final _name = TextEditingController(text: widget.handler.name);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => ref
          .read(challanRepositoryProvider)
          .renameCustomHandler(widget.handler.id, _name.text.trim()),
      onSuccess: () {
        ref.read(challansRevisionProvider.notifier).bump();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      key: const Key('handler-rename-dialog'),
      title: 'Rename',
      description: 'Challans already made keep the old name.',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        TextFormField(
          controller: _name,
          autofocus: !FormDialog.isCompact(context),
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
      ],
    );
  }
}
