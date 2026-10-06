import 'package:flutter/material.dart';

import '../utils/status_metadata.dart';

/// A person's or company's initials on the theme's primaryContainer — one
/// colour for everyone, matching the nav pill and Flutter's M3 CircleAvatar
/// default (the quieter secondaryContainer read as dull grey in dark mode).
/// [dimmed] for inactive employees and archived clients.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius,
    this.dimmed = false,
  });

  final String name;
  final double? radius;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: dimmed
          ? scheme.surfaceContainerHighest
          : scheme.primaryContainer,
      foregroundColor: dimmed
          ? scheme.onSurfaceVariant
          : scheme.onPrimaryContainer,
      child: Text(
        initialsFor(name),
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: radius == null ? null : radius! * 0.7,
        ),
      ),
    );
  }
}
