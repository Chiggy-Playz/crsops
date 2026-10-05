import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_format.dart';
import '../../models/day_status.dart';
import '../../models/effective_status_row.dart';
import '../../models/status_type.dart';
import 'day_cell.dart';
import 'month_calendar.dart';

/// A [MonthCalendar] showing attendance: a coloured dot per status marked
/// that day, a warning marker on past days someone was left unmarked, and
/// both read out to screen readers. Used by the Calendar page and Reports.
class AttendanceMonthCalendar extends StatelessWidget {
  const AttendanceMonthCalendar({
    super.key,
    required this.month,
    required this.rows,
    required this.statusTypes,
    required this.onMonthChanged,
    required this.onDateTap,
    this.selectedDate,
    this.firstDate,
    this.lastDate,
  });

  /// Any day in the month to show.
  final DateTime month;

  /// Attendance rows covering at least the shown month. Gaps are worked out
  /// from these, so any month or range shows its own gaps.
  final List<EffectiveStatusRow> rows;
  final List<StatusType> statusTypes;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateTap;
  final DateTime? selectedDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final colorHexByStatusId = <String, String>{
      for (final t in statusTypes)
        if (t.colorHex != null) t.id: t.colorHex!,
    };
    final labelByStatusId = <String, String>{
      for (final t in statusTypes) t.id: t.label,
    };
    final rowsByDate = groupRowsByDate(rows);

    List<EffectiveStatusRow> rowsOn(DateTime day) =>
        rowsByDate[dateOnly(day)] ?? const [];

    return MonthCalendar(
      month: month,
      selectedDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      onMonthChanged: onMonthChanged,
      onDateTap: onDateTap,
      dayBuilder: (context, day, {required isToday, required isSelected}) {
        final dayRows = rowsOn(day);
        return DayCell(
          day: day,
          isToday: isToday,
          isSelected: isSelected,
          hasGap: hasUnmarkedPastDay(dayRows, day),
          statusDots: statusDotsFor(dayRows, colorHexByStatusId),
        );
      },
      semanticLabelFor: (day) {
        final dayRows = rowsOn(day);
        final summary = statusSummaryLabel(dayRows, labelByStatusId);
        String? gap;
        if (hasUnmarkedPastDay(dayRows, day)) gap = 'attendance missing';
        final parts = [?summary, ?gap];
        if (parts.isEmpty) return null;
        return parts.join(', ');
      },
    );
  }
}
