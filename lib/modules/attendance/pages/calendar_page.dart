import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_key.dart';
import '../attendance_calendar_colors.dart';
import '../routes.dart';
import '../models/effective_status_row.dart';
import '../providers/attendance_providers.dart';
import 'widgets/day_cell.dart';
import 'widgets/month_calendar.dart';

/// The month calendar: a full page on narrow windows, the left pane of the
/// attendance two-pane layout on wide ones. [selectedDate] is the date open in
/// the right pane (wide only); tapping a date opens it the right way for the
/// layout (see [openInPane]).
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.selectedDate});

  final DateTime? selectedDate;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay = widget.selectedDate ?? DateTime.now();

  @override
  void didUpdateWidget(CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the selection when it moves (e.g. browser back to another month).
    final selected = widget.selectedDate;
    if (selected != null && selected != oldWidget.selectedDate) {
      _focusedDay = selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gapsAsync = ref.watch(recentGapsProvider);
    final gapDates =
        gapsAsync.value?.map((g) => dateOnly(g.date)).toSet() ?? {};

    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final monthStatusAsync = ref.watch(
      effectiveRangeStatusProvider(start: monthStart, end: monthEnd),
    );
    final statusTypesAsync = ref.watch(statusTypesProvider);
    final colorHexByStatusId = <String, String>{
      for (final t in statusTypesAsync.value ?? const [])
        if (t.colorHex != null) t.id: t.colorHex!,
    };
    final labelByStatusId = <String, String>{
      for (final t in statusTypesAsync.value ?? const []) t.id: t.label,
    };
    final rowsByDate = groupRowsByDate(
      monthStatusAsync.value ?? const <EffectiveStatusRow>[],
    );

    Widget cell(
      BuildContext context,
      DateTime day, {
      required bool isToday,
      required bool isSelected,
    }) {
      final dateKey = dateOnly(day);
      return DayCell(
        day: day,
        isToday: isToday,
        isSelected: isSelected,
        hasGap: gapDates.contains(dateKey),
        statusDots: statusDotsFor(
          rowsByDate[dateKey] ?? const [],
          colorHexByStatusId,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reports',
            onPressed: () => const ReportsRoute().push(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          MonthCalendar(
            month: _focusedDay,
            selectedDate: widget.selectedDate,
            onMonthChanged: (month) => setState(() => _focusedDay = month),
            onDateTap: (day) =>
                openInPane(context, AttendanceDayRoute(dateOnly(day)).location),
            dayBuilder: cell,
            semanticLabelFor: (day) {
              final dateKey = dateOnly(day);
              final summary = statusSummaryLabel(
                rowsByDate[dateKey] ?? const [],
                labelByStatusId,
              );
              final gap = gapDates.contains(dateKey)
                  ? 'attendance missing'
                  : null;
              final parts = [?summary, ?gap];
              return parts.isEmpty ? null : parts.join(', ');
            },
          ),
        ],
      ),
    );
  }
}
