import 'package:flutter/material.dart';

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
  });

  final DateTime day;
  final bool hasGap;

  /// One dot per distinct status represented that day (not per employee) —
  /// e.g. a day with some present and some on leave shows two dots. An
  /// unmarked day (no explicit status, not week-off) contributes none; the
  /// gap-warning icon already signals that separately.
  final List<Color> statusDots;

  String get _dateKey => dateOnly(day);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${day.day}'),
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
                              color: color,
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
                color: Colors.orange,
                key: gapMarkerKey(_dateKey),
              ),
            ),
        ],
      ),
    );
  }
}
