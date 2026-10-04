import 'package:flutter/material.dart';

import '../../../widgets/status_metadata.dart';

/// Initials on the theme's neutral container colour — the same for everyone,
/// as M3 suggests when there are no photos. [dimmed] for inactive employees.
class EmployeeAvatar extends StatelessWidget {
  const EmployeeAvatar({
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
          : scheme.secondaryContainer,
      foregroundColor: dimmed
          ? scheme.onSurfaceVariant
          : scheme.onSecondaryContainer,
      child: Text(
        initialsFor(name),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: radius == null ? null : radius! * 0.7,
        ),
      ),
    );
  }
}
