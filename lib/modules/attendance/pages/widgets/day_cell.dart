import 'package:flutter/material.dart';

import '../../../../core/theme/custom_colors.dart';
import '../../../../core/utils/date_key.dart';

/// Key for the gap-warning marker of a day, shared with tests so the format
/// lives in one place. Takes the `yyyy-MM-dd` date key (see [dateOnly]).
Key gapMarkerKey(String dateKey) => Key('gap-marker-$dateKey');

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.hasGap,
    this.statusDots = const [],
    this.isToday = false,
  });

  final DateTime day;
  final bool hasGap;

  /// One dot per distinct status represented that day (not per employee) —
  /// e.g. a day with some present and some on leave shows two dots. An
  /// unmarked day (no explicit status, not week-off) contributes none; the
  /// gap-warning icon already signals that separately.
  final List<Color> statusDots;

  /// Today gets a primary-coloured ring. It's drawn by this cell (not the
  /// package's own today style) so it keeps its dots and gap marker.
  final bool isToday;

  String get _dateKey => dateOnly(day);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: isToday
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.primary, width: 1.5),
            )
          : null,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: isToday
                      ? TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        )
                      : null,
                ),
                if (statusDots.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in statusDots)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Same tuned colour as the day page's badges.
                              color: context.customColor(color).color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasGap)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.warning_amber,
                size: 12,
                color: context.appColors.warning.color,
                key: gapMarkerKey(_dateKey),
              ),
            ),
        ],
      ),
    );
  }
}
