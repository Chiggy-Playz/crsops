import 'package:flutter/material.dart';

import 'inset_list_tile.dart';

/// An action shown as the first row of a list ("New employee", "Mark all
/// present"): the icon in an avatar-sized circle so it lines up with the rows
/// below, the label in the primary colour so it reads as an action. Used on
/// wide windows, where it sits right next to the content it adds to — a
/// floating button in a tall pane ends up far from a short list.
class ListActionRow extends StatelessWidget {
  const ListActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InsetListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(label, style: TextStyle(color: scheme.primary)),
      onTap: onTap,
    );
  }
}
