import 'package:flutter/material.dart';

import '../../../../core/widgets/inset_list_tile.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../models/challan.dart';

/// A challan in a list: its number, who it's for, the date and what's on it,
/// with a mark for cancelled or received.
class ChallanTile extends StatelessWidget {
  const ChallanTile({
    super.key,
    required this.challan,
    required this.onTap,
    this.selected = false,
    this.showDirection = false,
  });

  final Challan challan;
  final VoidCallback onTap;
  final bool selected;

  /// For lists that mix outward and inward (a client's challans).
  final bool showDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    final datePart = formatDisplayDate(challan.challanDate);
    final directionPart = showDirection ? '${challan.direction.label} · ' : '';

    final Widget? trailing;
    if (challan.isCancelled) {
      trailing = Text(
        'Cancelled',
        style: theme.textTheme.labelMedium?.copyWith(color: scheme.error),
      );
    } else if (challan.receivedOn != null) {
      trailing = Tooltip(
        message: 'Received',
        child: Icon(Icons.task_alt, color: scheme.primary),
      );
    } else {
      trailing = null;
    }

    return InsetListTile(
      leading: SizedBox(
        width: 48,
        child: Text(
          '${challan.number}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: challan.isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
      title: Text(
        challan.clientName,
        style: challan.isCancelled ? muted : null,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$directionPart$datePart · ${challan.itemsSummary}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      selected: selected,
      onTap: onTap,
    );
  }
}
