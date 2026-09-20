import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../widgets/guarded_save.dart';
import '../../../widgets/typeahead_picker_field.dart';
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

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !_saving &&
      double.tryParse(_amountController.text) != null &&
      _typedEntryType.trim().isNotEmpty;

  Future<void> _save() async {
    final amount = double.parse(_amountController.text);
    final entryType = _typedEntryType.trim();
    if (entryType.isEmpty || _saving) return;

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

    return AlertDialog(
      key: const Key('add-payment-dialog'),
      title: Text(_isEditing ? 'Edit payment' : 'Add payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('payment-amount-field'),
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              suffixIcon: Icon(Icons.calendar_month),
            ),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _entryDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _entryDate = picked);
              },
              child: Text(_dateFormat.format(_entryDate)),
            ),
          ),
          const SizedBox(height: 8),
          entryTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => TypeaheadPickerField(
              fieldKey: const Key('payment-category-field'),
              options: types,
              labelText: 'Category (existing or new)',
              initialValue: widget.existing?.label,
              onChanged: (value) => setState(() => _typedEntryType = value),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('payment-save-button'),
          onPressed: _canSave ? _save : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
