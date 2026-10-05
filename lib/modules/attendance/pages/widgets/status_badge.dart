import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/utils/status_metadata.dart';
import '../../models/status_type.dart';

/// A day's status at a glance, in the leading slot of a marking row:
/// - one status → a circle in that status's colour with its icon
/// - split day (different halves) → left half / right half in each colour
/// - unmarked → an empty outlined circle
///
/// Colours go through M3 custom-colour roles, so they're tuned for light and
/// dark mode rather than drawn straight from the stored hex.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.firstHalf,
    required this.secondHalf,
    this.radius = 20,
  });

  /// Null = unmarked. A week-off day with no mark is passed as the week-off
  /// type for both halves.
  final StatusType? firstHalf;
  final StatusType? secondHalf;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final first = firstHalf;
    final second = secondHalf ?? firstHalf;
    final size = radius * 2;

    if (first == null) {
      return Semantics(
        label: 'Unmarked',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1.5,
            ),
          ),
        ),
      );
    }

    final firstRoles = context.customColor(colorFor(first.colorHex));

    if (second == null || second.id == first.id) {
      return Semantics(
        label: first.label,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: firstRoles.color,
          foregroundColor: firstRoles.onColor,
          child: Icon(iconFor(first.iconName), size: radius),
        ),
      );
    }

    final secondRoles = context.customColor(colorFor(second.colorHex));
    return Semantics(
      label: '${first.label} / ${second.label}',
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Row(
            children: [
              Expanded(child: ColoredBox(color: firstRoles.color)),
              Expanded(child: ColoredBox(color: secondRoles.color)),
            ],
          ),
        ),
      ),
    );
  }
}
