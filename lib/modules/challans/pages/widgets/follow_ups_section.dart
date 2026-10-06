import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../models/challan.dart';
import '../../providers/challan_providers.dart';
import 'challan_action.dart';

/// What happens after an outward challan goes out: the signed copy coming
/// back, the bill, the digital signature. Each saves on its own. Read-only
/// once the challan is cancelled.
class FollowUpsSection extends ConsumerWidget {
  const FollowUpsSection({super.key, required this.challan});

  final Challan challan;

  Future<void> _pickReceivedDate(BuildContext context, WidgetRef ref) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      helpText: 'Signed copy received on',
      initialDate: challan.receivedOn ?? today,
      firstDate: challan.challanDate,
      lastDate: today,
    );
    if (picked == null) return;
    await runChallanAction(
      ref,
      () => ref.read(challanRepositoryProvider).setReceived(challan.id, picked),
    );
  }

  Future<void> _editBillNumber(BuildContext context, WidgetRef ref) async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => _BillNumberDialog(initial: challan.billNumber ?? ''),
    );
    if (entered == null) return;
    final trimmed = entered.trim();
    await runChallanAction(
      ref,
      () => ref
          .read(challanRepositoryProvider)
          .setBillNumber(challan.id, trimmed.isEmpty ? null : trimmed),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = challan.isCancelled;
    final receivedOn = challan.receivedOn;
    final billNumber = challan.billNumber;
    final repo = ref.read(challanRepositoryProvider);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            receivedOn == null ? Icons.pending_actions : Icons.task_alt,
          ),
          title: const Text('Signed copy received'),
          subtitle: Text(
            receivedOn == null ? 'Not yet' : formatDisplayDate(receivedOn),
          ),
          enabled: !locked,
          onTap: () => _pickReceivedDate(context, ref),
          trailing: receivedOn == null || locked
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Mark not received',
                  onPressed: () => runChallanAction(
                    ref,
                    () => repo.setReceived(challan.id, null),
                  ),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_outlined),
          title: const Text('Bill number'),
          subtitle: Text(billNumber ?? 'None'),
          enabled: !locked,
          onTap: () => _editBillNumber(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.draw_outlined),
          title: const Text('Digitally signed'),
          value: challan.digitallySigned,
          onChanged: locked
              ? null
              : (signed) => runChallanAction(
                  ref,
                  () => repo.setDigitallySigned(challan.id, signed: signed),
                ),
        ),
      ],
    );
  }
}

class _BillNumberDialog extends StatefulWidget {
  const _BillNumberDialog({required this.initial});

  final String initial;

  @override
  State<_BillNumberDialog> createState() => _BillNumberDialogState();
}

class _BillNumberDialogState extends State<_BillNumberDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bill number'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Bill number',
          helperText: 'Leave empty to remove it',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
