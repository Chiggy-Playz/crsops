import 'package:flutter/material.dart';

/// A row of a list-detail list (clients, challans, employees, settings):
/// inset from the pane's edges with a little space between rows, and the
/// selected row shown as a rounded highlight, like the navigation drawer's.
/// The content still lines up with [SectionHeader]s, 16 px in.
class PaneListTile extends StatelessWidget {
  const PaneListTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final Widget title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;

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
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        onTap: onTap,
      ),
    );
  }
}
