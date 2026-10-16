import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/utils/status_metadata.dart';
import '../../models/status_type.dart';

/// A day's status at a glance, in the leading slot of a marking row:
/// - a status → a circle in that status's colour with its icon
/// - unmarked → an empty outlined circle
///
/// Colours go through M3 custom-colour roles, so they're tuned for light and
/// dark mode rather than drawn straight from the stored hex.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.radius = 20});

  /// Null = unmarked. A week-off day with no mark is passed as the week-off
  /// type.
  final StatusType? status;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final type = status;
    if (type == null) {
      final size = radius * 2;
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

    final roles = context.customColor(colorFor(type.colorHex));
    return Semantics(
      label: type.label,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: roles.color,
        foregroundColor: roles.onColor,
        child: Icon(iconFor(type.iconName), size: radius),
      ),
    );
  }
}
