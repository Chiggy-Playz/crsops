import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/overflow_menu.dart';
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
      unit = TextEditingController(text: item?.unit ?? ''),
      showSecondLine = (item?.additionalDescription ?? '').isNotEmpty;

  /// Tells the rows apart when one is removed or moved.
  final key = UniqueKey();
  final TextEditingController description;
  final TextEditingController additionalDescription;
  final TextEditingController serial;
  final TextEditingController quantity;
  final TextEditingController unit;

  /// So a new row, or a second line just asked for, can take the cursor.
  final descriptionFocus = FocusNode();
  final secondLineFocus = FocusNode();

  /// Most items have no second line, so its field shows only once asked for.
  bool showSecondLine;

  /// Only call once the form has validated: the quantity is then a number.
  ChallanItem toItem() => ChallanItem(
    description: description.text.trim(),
    additionalDescription: showSecondLine
        ? _nullIfBlank(additionalDescription.text)
        : null,
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
    descriptionFocus.dispose();
    secondLineFocus.dispose();
  }

  static String? _nullIfBlank(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// The items of the challan form, laid out like the printed challan: one row
/// per item under column headings, with the total quantity at the bottom.
/// Narrow windows give each item two lines (description, then serial,
/// quantity and unit) with the labels on the fields.
///
/// Keyboard: Tab walks along a row and on to the next; Enter in the last
/// row's unit adds a row and moves to it.
class ItemsEditor extends StatefulWidget {
  const ItemsEditor({
    super.key,
    required this.items,
    required this.units,
    required this.onAdd,
    required this.onRemove,
    required this.onMove,
    required this.onEdited,
  });

  final List<ItemFormValues> items;

  /// Units typed before, offered as suggestions.
  final List<String> units;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int from, int to) onMove;

  /// Something changed that isn't a field edit (a second line hidden).
  final VoidCallback onEdited;

  /// Narrower than this, each item takes two lines.
  static const double tableWidth = 560;

  @override
  State<ItemsEditor> createState() => _ItemsEditorState();
}

class _ItemsEditorState extends State<ItemsEditor> {
  void _addAndFocus() {
    widget.onAdd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.items.last.descriptionFocus.requestFocus();
    });
  }

  void _setSecondLine(ItemFormValues item, bool show) {
    setState(() => item.showSecondLine = show);
    if (show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) item.secondLineFocus.requestFocus();
      });
    } else {
      item.additionalDescription.clear();
      widget.onEdited();
    }
  }

  List<OverflowMenuItem> _menuItems(int index) {
    final item = widget.items[index];
    final isLast = index == widget.items.length - 1;
    return [
      if (item.showSecondLine)
        OverflowMenuItem(
          label: 'Remove second line',
          icon: Icons.playlist_remove,
          onPressed: () => _setSecondLine(item, false),
        )
      else
        OverflowMenuItem(
          label: 'Add second line',
          icon: Icons.playlist_add,
          onPressed: () => _setSecondLine(item, true),
        ),
      if (index > 0)
        OverflowMenuItem(
          label: 'Move up',
          icon: Icons.arrow_upward,
          onPressed: () => widget.onMove(index, index - 1),
        ),
      if (!isLast)
        OverflowMenuItem(
          label: 'Move down',
          icon: Icons.arrow_downward,
          onPressed: () => widget.onMove(index, index + 1),
        ),
      if (widget.items.length > 1)
        OverflowMenuItem(
          label: 'Remove item',
          icon: Icons.delete_outline,
          destructive: true,
          onPressed: () => widget.onRemove(index),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final asTable = constraints.maxWidth >= ItemsEditor.tableWidth;

        return Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (asTable) ...[const _HeadingRow(), const Divider(height: 1)],
              for (final (index, item) in widget.items.indexed) ...[
                if (index > 0) const Divider(height: 1),
                _ItemRow(
                  key: item.key,
                  position: index + 1,
                  values: item,
                  units: widget.units,
                  asTable: asTable,
                  isLast: index == widget.items.length - 1,
                  menuItems: _menuItems(index),
                  onSubmittedLast: _addAndFocus,
                ),
              ],
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _addAndFocus,
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                    const Spacer(),
                    // Rebuilds as quantities are typed.
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        for (final item in widget.items) item.quantity,
                      ]),
                      builder: (context, _) {
                        final total = widget.items.fold<int>(
                          0,
                          (sum, item) =>
                              sum +
                              (int.tryParse(item.quantity.text.trim()) ?? 0),
                        );
                        return Text(
                          'Total $total',
                          style: theme.textTheme.titleSmall,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Column widths, shared by the headings and the rows so they line up.
const double _numberWidth = 32;
const double _quantityWidth = 80;
const double _unitWidth = 104;
const double _menuWidth = 48;
const double _gap = 12;
const int _descriptionFlex = 2;
const int _serialFlex = 1;

class _HeadingRow extends StatelessWidget {
  const _HeadingRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          spacing: _gap,
          children: [
            SizedBox(
              width: _numberWidth,
              child: Text('#', style: style),
            ),
            Expanded(
              flex: _descriptionFlex,
              child: Text('Description', style: style),
            ),
            Expanded(
              flex: _serialFlex,
              child: Text('Serial', style: style),
            ),
            SizedBox(
              width: _quantityWidth,
              child: Text('Qty', style: style),
            ),
            SizedBox(
              width: _unitWidth,
              child: Text('Unit', style: style),
            ),
            const SizedBox(width: _menuWidth),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.position,
    required this.values,
    required this.units,
    required this.asTable,
    required this.isLast,
    required this.menuItems,
    required this.onSubmittedLast,
  });

  /// 1-based, as printed.
  final int position;
  final ItemFormValues values;
  final List<String> units;

  /// One row under column headings (the headings name the fields), or two
  /// lines with labels on the fields.
  final bool asTable;
  final bool isLast;
  final List<OverflowMenuItem> menuItems;

  /// Enter in the last row's unit field.
  final VoidCallback onSubmittedLast;

  static String? _validateQuantity(String? value) {
    final quantity = int.tryParse((value ?? '').trim());
    if (quantity == null || quantity < 1) return 'At least 1';
    return null;
  }

  /// Under a column heading the field needs no label of its own (only the
  /// description and second line get a hint, for an empty row); on its own
  /// it gets one.
  InputDecoration _decoration(String name, {bool hintInTable = false}) {
    if (asTable) {
      return InputDecoration(
        hintText: hintInTable ? name : null,
        isDense: true,
        errorMaxLines: 2,
      );
    }
    return InputDecoration(labelText: name, errorMaxLines: 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final description = TextFormField(
      controller: values.description,
      focusNode: values.descriptionFocus,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      decoration: _decoration('Description', hintInTable: true),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? 'Enter a description' : null,
    );
    final secondLine = TextFormField(
      controller: values.additionalDescription,
      focusNode: values.secondLineFocus,
      textCapitalization: TextCapitalization.characters,
      minLines: 1,
      maxLines: 4,
      decoration: _decoration('Second line', hintInTable: true),
    );
    final serial = TextFormField(
      controller: values.serial,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      decoration: _decoration('Serial'),
    );
    final quantity = TextFormField(
      controller: values.quantity,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration('Qty'),
      validator: _validateQuantity,
    );
    final unit = SuggestionField(
      controller: values.unit,
      suggestions: units,
      label: asTable ? null : 'Unit',
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isLast ? onSubmittedLast : null,
    );
    final number = SizedBox(
      width: asTable ? _numberWidth : 24,
      child: Padding(
        // Level with the text in the field beside it.
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          '$position',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    final menu = SizedBox(
      width: _menuWidth,
      child: OverflowMenu(items: menuItems, tooltip: 'Item $position options'),
    );

    if (asTable) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _gap,
          children: [
            number,
            Expanded(
              flex: _descriptionFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [description, if (values.showSecondLine) secondLine],
              ),
            ),
            Expanded(flex: _serialFlex, child: serial),
            SizedBox(width: _quantityWidth, child: quantity),
            SizedBox(width: _unitWidth, child: unit),
            menu,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          number,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                description,
                if (values.showSecondLine) secondLine,
                // Shared by proportion: on a phone fixed widths would leave
                // the serial a sliver.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: _gap,
                  children: [
                    Expanded(flex: 3, child: serial),
                    Expanded(flex: 2, child: quantity),
                    Expanded(flex: 2, child: unit),
                  ],
                ),
              ],
            ),
          ),
          menu,
        ],
      ),
    );
  }
}
