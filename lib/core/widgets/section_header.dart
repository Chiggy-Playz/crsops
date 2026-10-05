import 'package:flutter/material.dart';

/// The small primary-coloured heading above a group of list rows
/// ("Appearance", "History", "Inactive"). Marked as a header so screen
/// readers can jump between groups.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.topPadding = 24});

  final String title;

  /// Space above the heading; smaller where the list is already tight.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
