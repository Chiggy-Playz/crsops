import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/form_dialog.dart';
import '../../../widgets/guarded_save.dart';
import '../../../widgets/creatable_dropdown_field.dart';
import '../../models/timeline_entry.dart';
import '../../providers/employee_providers.dart';

Future<void> showAddPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  String employeeId, {
  TimelineEntry? existing,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _AddPaymentDialog(employeeId: employeeId, existing: existing),
  );
}

final _dateFormat = DateFormat('d MMM yyyy');

class _AddPaymentDialog extends ConsumerStatefulWidget {
  const _AddPaymentDialog({required this.employeeId, this.existing});
  final String employeeId;
  final TimelineEntry? existing;

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  late final _amountController = TextEditingController(
    text: widget.existing?.amount?.toStringAsFixed(0) ?? '',
  );
  late final _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late String _typedEntryType = widget.existing?.label ?? '';
  late DateTime _entryDate = widget.existing?.entryDate ?? DateTime.now();
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final amount = double.parse(_amountController.text.trim());
    final entryType = _typedEntryType.trim();

    await runGuardedSave(
      context,
      setSaving: (v) => setState(() => _saving = v),
      action: () async {
        final note = _noteController.text.isEmpty ? null : _noteController.text;
        if (_isEditing) {
          await ref
              .read(employeeLedgerEntryRepositoryProvider)
              .updateEntry(
                id: widget.existing!.id,
                entryDate: _entryDate,
                amount: amount,
                entryType: entryType,
                note: note,
              );
        } else {
          await ref
              .read(employeeLedgerEntryRepositoryProvider)
              .addEntry(
                employeeId: widget.employeeId,
                entryDate: _entryDate,
                amount: amount,
                entryType: entryType,
                note: note,
              );
        }
      },
      onSuccess: () {
        ref.invalidate(distinctEntryTypesProvider);
        ref.invalidate(employeeTimelineProvider(widget.employeeId));
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final entryTypesAsync = ref.watch(distinctEntryTypesProvider);

    return FormDialog(
      key: const Key('add-payment-dialog'),
      title: _isEditing ? 'Edit payment' : 'Add payment',
      formKey: _formKey,
      saving: _saving,
      saveButtonKey: const Key('payment-save-button'),
      onSave: _save,
      children: [
        entryTypesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('$error'),
          data: (types) => CreatableDropdownField(
            fieldKey: const Key('payment-category-field'),
            options: types,
            label: 'Category',
            helperText: 'Pick one, or type to add a new one',
            initialValue: widget.existing?.label,
            autofocus: !FormDialog.isCompact(context),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Choose a category' : null,
            onChanged: (value) => _typedEntryType = value,
          ),
        ),
        TextFormField(
          key: const Key('payment-amount-field'),
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Enter an amount';
            if (double.tryParse(text) == null) return 'Enter a number';
            return null;
          },
        ),
        DateFormField(
          label: 'Date',
          value: _entryDate,
          format: _dateFormat.format,
          onChanged: (d) => setState(() => _entryDate = d),
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
