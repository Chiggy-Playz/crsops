import 'package:flutter/material.dart';

import '../../../core/layout/two_pane_layout.dart';
import 'calendar_page.dart';

/// Attendance on wide windows: the calendar on the left, the selected day
/// (the routed [child]) on the right. Narrow windows show [child] alone.
class AttendanceSplitLayout extends StatelessWidget {
  const AttendanceSplitLayout({
    super.key,
    required this.selectedDate,
    required this.child,
  });

  final DateTime? selectedDate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TwoPaneLayout(
      // A month grid needs more room than a list pane.
      paneWidth: 480,
      pane: CalendarPage(selectedDate: selectedDate),
      child: child,
    );
  }
}
