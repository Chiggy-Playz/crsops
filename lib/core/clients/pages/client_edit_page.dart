import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/window_size.dart';
import '../../widgets/form_pane.dart';
import '../../widgets/guarded_save.dart';
import '../../widgets/section_header.dart';
import '../gstin.dart';
import '../models/client.dart';
import '../providers/client_providers.dart';
import '../routes.dart';
import 'widgets/address_form_fields.dart';

/// New client (with its first address, since a client needs one to go on a
/// challan) or editing a client's name and notes: the right pane on wide
/// windows, a page on phones. Addresses are edited on their own form, from
/// the client's page.
class ClientEditPage extends ConsumerStatefulWidget {
  const ClientEditPage({super.key, required this.existing});

  final Client? existing;

  @override
  ConsumerState<ClientEditPage> createState() => _ClientEditPageState();
}

class _ClientEditPageState extends ConsumerState<ClientEditPage> {
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.existing?.notes ?? '',
  );
  final _address = AddressFormValues(label: 'Main');
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  /// Anything entered since the form opened, so leaving asks first.
  bool _changed = false;

  bool get _isEditing => widget.existing != null;

  /// "Name on challan" copies the client name as it's typed, until the
  /// person types something different there.
  String _lastCopiedName = '';

  @override
  void initState() {
    super.initState();
    if (!_isEditing) _nameController.addListener(_copyNameToChallanName);
  }

  void _copyNameToChallanName() {
    final nameOnChallan = _address.nameOnChallan;
    if (nameOnChallan.text != _lastCopiedName) return;
    _lastCopiedName = _nameController.text;
    nameOnChallan.text = _nameController.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final repo = ref.read(clientRepositoryProvider);
    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    String? newClientId;

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        if (_isEditing) {
          await repo.update(
            id: widget.existing!.id,
            name: name,
            notes: notes.isEmpty ? null : notes,
          );
        } else {
          newClientId = await repo.create(
            name: name,
            notes: notes.isEmpty ? null : notes,
            label: _address.label.text,
            nameOnChallan: _address.nameOnChallan.text,
            address: _address.address.text,
            stateCode: _address.stateCode!,
            gstin: cleanGstin(_address.gstin.text),
          );
        }
      },
      onSuccess: () {
        ref.read(clientsRevisionProvider.notifier).bump();
        // Saved: nothing to ask about on the way out.
        _changed = false;
        final createdId = newClientId;
        if (createdId == null) {
          Navigator.of(context).pop();
        } else {
          ClientDetailRoute(createdId).go(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(indianStatesProvider);

    final existing = widget.existing;

    return FormPane(
      title: _isEditing ? 'Edit client' : 'New client',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      onChanged: () => _changed = true,
      hasUnsavedChanges: () => _changed,
      closeLocation: existing == null
          ? const ClientsRoute().location
          : ClientDetailRoute(existing.id).location,
      children: [
        TextFormField(
          controller: _nameController,
          // Not on phones, where it would pop the keyboard over the form.
          autofocus: context.windowSize != WindowSize.compact,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Client name'),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            helperText: 'Only for you, like who referred them',
          ),
          minLines: 1,
          maxLines: 4,
        ),
        if (!_isEditing) ...[
          const SectionHeader('First address'),
          statesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
            data: (states) =>
                AddressFormFields(values: _address, states: states),
          ),
        ],
      ],
    );
  }
}
