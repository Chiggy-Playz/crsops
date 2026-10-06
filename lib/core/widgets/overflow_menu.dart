import 'package:flutter/material.dart';

/// One entry of an [OverflowMenu].
class OverflowMenuItem {
  const OverflowMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Shown in the error colour (Delete, Cancel challan), so it doesn't look
  /// as harmless as the rest.
  final bool destructive;
}

/// The ⋮ button and its menu: M3 MenuAnchor (keyboard navigation, focus
/// handling, open/close motion) rather than the older PopupMenuButton.
/// Another [icon] makes it a named menu button (e.g. Export).
class OverflowMenu extends StatelessWidget {
  const OverflowMenu({
    super.key,
    required this.items,
    this.tooltip = 'More options',
    this.icon = Icons.more_vert,
  });

  final List<OverflowMenuItem> items;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return MenuAnchor(
      // Off by default in Flutter; turns on the M3 open/close motion.
      animated: true,
      menuChildren: [
        for (final item in items)
          MenuItemButton(
            leadingIcon: item.icon == null
                ? null
                : Icon(item.icon, color: item.destructive ? error : null),
            style: item.destructive
                ? MenuItemButton.styleFrom(foregroundColor: error)
                : null,
            onPressed: item.onPressed,
            child: Text(item.label),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
