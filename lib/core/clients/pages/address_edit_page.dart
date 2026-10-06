import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/form_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../gstin.dart';
import '../models/client_address.dart';
import '../providers/client_providers.dart';
import 'widgets/address_form_fields.dart';

/// Adds an address to a client, or edits one. Challans already made keep the
/// details they were made with: the database saves an edit as a new version
/// when a challan uses the current one.
class AddressEditPage extends ConsumerStatefulWidget {
  const AddressEditPage({
    super.key,
    required this.clientId,
    required this.existing,
    this.defaultNameOnChallan = '',
  });

  final String clientId;
  final ClientAddress? existing;

  /// What "Name on challan" starts as for a new address: the client's name.
  final String defaultNameOnChallan;

  @override
  ConsumerState<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends ConsumerState<AddressEditPage> {
  late final _values = AddressFormValues(
    label: widget.existing?.label ?? '',
    nameOnChallan:
        widget.existing?.nameOnChallan ?? widget.defaultNameOnChallan,
    address: widget.existing?.address ?? '',
    stateCode: widget.existing?.stateCode,
    gstin: widget.existing?.gstin ?? '',
  );
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _values.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final repo = ref.read(clientRepositoryProvider);

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () => repo.saveAddress(
        addressId: widget.existing?.addressId,
        clientId: widget.clientId,
        label: _values.label.text,
        nameOnChallan: _values.nameOnChallan.text,
        address: _values.address.text,
        stateCode: _values.stateCode!,
        gstin: cleanGstin(_values.gstin.text),
      ),
      onSuccess: () {
        ref.read(clientsRevisionProvider.notifier).bump();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final statesAsync = ref.watch(indianStatesProvider);

    return FormDialog(
      title: widget.existing == null ? 'New address' : 'Edit address',
      description: widget.existing == null
          ? null
          : 'Challans already made keep the old details.',
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      children: [
        statesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (states) => AddressFormFields(values: _values, states: states),
        ),
      ],
    );
  }
}
