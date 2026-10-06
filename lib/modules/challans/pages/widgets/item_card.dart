import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/challan_item.dart';
import 'suggestion_field.dart';

/// The text controllers behind one item in the challan form.
class ItemFormValues {
  ItemFormValues([ChallanItem? item])
    : description = TextEditingController(text: item?.description ?? ''),
      additionalDescription = TextEditingController(
        text: item?.additionalDescription ?? '',
      ),
      serial = TextEditingController(text: item?.serial ?? ''),
      quantity = TextEditingController(text: '${item?.quantity ?? 1}'),
      unit = TextEditingController(text: item?.unit ?? '');

  /// Tells the cards apart when one is removed or moved.
  final key = UniqueKey();
  final TextEditingController description;
  final TextEditingController additionalDescription;
  final TextEditingController serial;
  final TextEditingController quantity;
  final TextEditingController unit;

  /// Only call once the form has validated: the quantity is then a number.
  ChallanItem toItem() => ChallanItem(
    description: description.text.trim(),
    additionalDescription: _nullIfBlank(additionalDescription.text),
    serial: _nullIfBlank(serial.text),
    quantity: int.parse(quantity.text.trim()),
    unit: _nullIfBlank(unit.text)?.toUpperCase(),
  );

  void dispose() {
    description.dispose();
    additionalDescription.dispose();
    serial.dispose();
    quantity.dispose();
    unit.dispose();
  }

  static String? _nullIfBlank(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// One item of the challan form, in an outlined card with its number and
/// buttons to move it or remove it.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.position,
    required this.values,
    required this.units,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  /// 1-based, as printed.
  final int position;
  final ItemFormValues values;
  final List<String> units;

  /// Null when the button should be hidden (the only item can't be removed;
  /// the first can't move up, the last can't move down).
  final VoidCallback? onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  static String? _validateQuantity(String? value) {
    final quantity = int.tryParse((value ?? '').trim());
    if (quantity == null || quantity < 1) return 'At least 1';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item $position',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (onMoveUp != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Move up',
                    onPressed: onMoveUp,
                  ),
                if (onMoveDown != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: 'Move down',
                    onPressed: onMoveDown,
                  ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove item $position',
                    onPressed: onRemove,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  TextFormField(
                    controller: values.description,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter a description'
                        : null,
                  ),
                  TextFormField(
                    controller: values.additionalDescription,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Second line (optional)',
                      helperText: 'Printed under the description',
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                  TextFormField(
                    controller: values.serial,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Serial (optional)',
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: values.quantity,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                          validator: _validateQuantity,
                        ),
                      ),
                      Expanded(
                        child: SuggestionField(
                          controller: values.unit,
                          suggestions: units,
                          label: 'Unit (optional)',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
