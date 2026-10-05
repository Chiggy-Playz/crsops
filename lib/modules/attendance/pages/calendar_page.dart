import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_time_format.dart';
import '../providers/attendance_providers.dart';
import '../routes.dart';
import 'widgets/attendance_month_calendar.dart';

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
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final monthStatusAsync = ref.watch(
      effectiveRangeStatusProvider(start: monthStart, end: monthEnd),
    );
    final statusTypesAsync = ref.watch(statusTypesProvider);

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
          AttendanceMonthCalendar(
            month: _focusedDay,
            rows: monthStatusAsync.value ?? const [],
            statusTypes: statusTypesAsync.value ?? const [],
            selectedDate: widget.selectedDate,
            onMonthChanged: (month) => setState(() => _focusedDay = month),
            onDateTap: (day) =>
                openInPane(context, AttendanceDayRoute(dateOnly(day)).location),
          ),
        ],
      ),
    );
  }
}
