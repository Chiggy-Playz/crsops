import 'package:flutter/material.dart';

/// A tappable row of a list (clients, challans, employees, settings,
/// addresses, the "New …" rows): inset from the edges with a little space
/// between rows, so hover and the selected row show as rounded highlights,
/// like the navigation drawer's. The content still lines up with
/// [SectionHeader]s, 16 px in.
class InsetListTile extends StatelessWidget {
  const InsetListTile({
    super.key,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.isThreeLine = false,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onLongPress,
  });

  final Widget title;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final bool isThreeLine;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        isThreeLine: isThreeLine,
        enabled: enabled,
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
