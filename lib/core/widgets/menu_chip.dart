import 'package:flutter/material.dart';

class MenuChipOption<T> {
  const MenuChipOption(this.value, this.label);

  final T value;
  final String label;
}

/// A filter chip that opens a menu anchored under it to pick one value (a
/// financial year, a direction), as the Reports range chip does. The picked
/// option shows a check mark.
class MenuChip<T> extends StatelessWidget {
  const MenuChip({
    super.key,
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;

  /// What the chip says: usually the picked option's label.
  final String label;
  final List<MenuChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      animated: true,
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            trailingIcon: option.value == selected
                ? const Icon(Icons.check)
                : null,
            onPressed: () => onSelected(option.value),
            child: Text(option.label),
          ),
      ],
      builder: (context, controller, _) => InputChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        deleteIcon: const Icon(Icons.arrow_drop_down, size: 18),
        // The drop-down arrow, not a delete: it opens the menu too.
        onDeleted: () =>
            controller.isOpen ? controller.close() : controller.open(),
        deleteButtonTooltipMessage: '',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
