import 'package:flutter/material.dart';

import '../../../../core/widgets/inset_list_tile.dart';
import '../../../../core/utils/date_time_format.dart';
import '../../models/challan.dart';

/// A challan in a list: its number, who it's for, the date and what's on it,
/// with a mark for cancelled or received. Under a heading that already names
/// the client ([showClient] false), what's on it is the title instead of the
/// client's name repeated on every row.
class ChallanTile extends StatelessWidget {
  const ChallanTile({
    super.key,
    required this.challan,
    required this.onTap,
    this.selected = false,
    this.showDirection = false,
    this.showClient = true,
    this.showAddress = false,
  });

  final Challan challan;
  final VoidCallback onTap;
  final bool selected;

  /// For lists that mix outward and inward (a client's challans).
  final bool showDirection;

  /// False where the client is named elsewhere (a heading, the client's own
  /// page): the items become the title.
  final bool showClient;

  /// With [showClient] false: add which of the client's addresses it went to
  /// (for a client whose challans span several).
  final bool showAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    // Each part only when it says something: the direction where outward
    // and inward mix, the count when there's more than one item.
    final parts = <String>[
      if (showDirection) challan.direction.label,
      formatDisplayDate(challan.challanDate),
      if (!showClient && showAddress) challan.addressLabel,
      if (challan.itemCount > 1) '${challan.itemCount} items',
      if (showClient && challan.firstItem != null) challan.firstItem!,
    ];
    final subtitleText = parts.join(' · ');
    final titleText = showClient
        ? challan.clientName
        : (challan.firstItem ?? '');

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
        titleText,
        style: challan.isCancelled ? muted : null,
        // Items run long, so they get a second line before being cut off.
        maxLines: showClient ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      selected: selected,
      onTap: onTap,
    );
  }
}
