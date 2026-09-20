import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/employee_providers.dart';

Future<void> showAddPaymentDialog(BuildContext context, WidgetRef ref, String employeeId) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AddPaymentDialog(employeeId: employeeId),
  );
}

class _AddPaymentDialog extends ConsumerStatefulWidget {
  const _AddPaymentDialog({required this.employeeId});
  final String employeeId;

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newTypeController = TextEditingController();
  String? _selectedType;
  bool _typingNewType = false;
  DateTime _entryDate = DateTime.now();

  bool get _canSave {
    final hasValidAmount = double.tryParse(_amountController.text) != null;
    final hasValidType = _typingNewType
        ? _newTypeController.text.trim().isNotEmpty
        : (_selectedType != null && _selectedType != '__new__');
    return hasValidAmount && hasValidType;
  }

  Future<void> _save() async {
    final amount = double.parse(_amountController.text);
    final entryType = _typingNewType ? _newTypeController.text : _selectedType;
    if (entryType == null || entryType.isEmpty || entryType == '__new__') return;

    await ref.read(employeeLedgerEntryRepositoryProvider).addEntry(
          employeeId: widget.employeeId,
          entryDate: _entryDate,
          amount: amount,
          entryType: entryType,
        );
    ref.invalidate(distinctEntryTypesProvider);
    ref.invalidate(employeeTimelineProvider(widget.employeeId));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final entryTypesAsync = ref.watch(distinctEntryTypesProvider);

    return AlertDialog(
      key: const Key('add-payment-dialog'),
      title: const Text('Add payment'),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date: ${_entryDate.toIso8601String().split('T').first}'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _entryDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _entryDate = picked);
            },
          ),
          entryTypesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (types) => DropdownButton<String>(
              value: _selectedType,
              hint: const Text('Category (e.g. advance, salary_payment)'),
              items: [
                ...types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                const DropdownMenuItem(value: '__new__', child: Text('+ New category')),
              ],
              onChanged: (value) => setState(() {
                _typingNewType = value == '__new__';
                _selectedType = value;
              }),
            ),
          ),
          if (_typingNewType)
            TextField(
              controller: _newTypeController,
              decoration: const InputDecoration(labelText: 'New category name'),
              onChanged: (_) => setState(() {}),
            ),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          key: const Key('payment-save-button'),
          onPressed: _canSave ? _save : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
