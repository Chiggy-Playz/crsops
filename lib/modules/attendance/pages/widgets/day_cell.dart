import 'package:flutter/material.dart';

class DayCell extends StatelessWidget {
  const DayCell({super.key, required this.day, required this.hasGap, this.summaryColor});

  final DateTime day;
  final bool hasGap;
  final Color? summaryColor;

  String get _dateKey => day.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: summaryColor?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          Center(child: Text('${day.day}')),
          if (hasGap)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(Icons.warning_amber, size: 12, color: Colors.orange, key: Key('gap-marker-$_dateKey')),
            ),
        ],
      ),
    );
  }
}
