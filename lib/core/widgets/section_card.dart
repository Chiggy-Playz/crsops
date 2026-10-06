import 'package:flutter/material.dart';

/// A titled, outlined block of a record's page (a challan, a client): an
/// icon and title at the top, then [child].
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// A button at the right of the title (e.g. "Open client").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Lower top padding with an action: its button is taller than the text.
    final double topPadding;
    if (action == null) {
      topPadding = 16;
    } else {
      topPadding = 6;
    }

    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding, 8, 8),
            child: Row(
              spacing: 8,
              children: [
                Icon(icon, size: 20, color: primary),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: primary,
                      ),
                    ),
                  ),
                ),
                ?action,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
