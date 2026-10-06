import 'package:flutter/material.dart';

import '../../models/challan.dart';

/// What the cancel dialog asked for.
class CancelChoice {
  const CancelChoice({required this.reason, required this.createReturn});

  final String? reason;

  /// Also make an inward challan bringing the goods back.
  final bool createReturn;
}

/// Confirms cancelling [challan], with an optional reason and (outward only)
/// the choice to bring the goods back on an inward challan. Null if dismissed.
Future<CancelChoice?> showCancelChallanDialog(
  BuildContext context,
  Challan challan,
) => showDialog<CancelChoice>(
  context: context,
  builder: (_) => _CancelChallanDialog(challan: challan),
);

class _CancelChallanDialog extends StatefulWidget {
  const _CancelChallanDialog({required this.challan});

  final Challan challan;

  @override
  State<_CancelChallanDialog> createState() => _CancelChallanDialogState();
}

class _CancelChallanDialogState extends State<_CancelChallanDialog> {
  final _reason = TextEditingController();
  bool _createReturn = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    Navigator.of(context).pop(
      CancelChoice(
        reason: reason.isEmpty ? null : reason,
        createReturn: _createReturn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challan = widget.challan;

    return AlertDialog(
      title: Text('Cancel challan ${challan.numberLabel}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "It keeps its number and can't be edited or un-cancelled "
            'afterwards.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            minLines: 1,
            maxLines: 3,
          ),
          if (challan.isOutward) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _createReturn,
              onChanged: (value) =>
                  setState(() => _createReturn = value ?? false),
              title: const Text('Bring the goods back in'),
              subtitle: const Text(
                'Makes an inward challan dated today with the same items',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep it'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _confirm,
          child: const Text('Cancel challan'),
        ),
      ],
    );
  }
}
