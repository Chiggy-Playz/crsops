import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/utils/date_key.dart';
import '../attendance_calendar_colors.dart';
import '../routes.dart';
import '../models/effective_status_row.dart';
import '../providers/attendance_providers.dart';
import 'widgets/day_cell.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();

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
    final rowsByDate = groupRowsByDate(
      monthStatusAsync.value ?? const <EffectiveStatusRow>[],
    );

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
      body: TableCalendar(
        firstDay: DateTime(2000, 1, 1),
        lastDay: DateTime(2100, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(formatButtonVisible: false),
        onPageChanged: (day) => setState(() => _focusedDay = day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay = focusedDay);
          AttendanceDayRoute(dateOnly(selectedDay)).push(context);
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final dateKey = dateOnly(day);
            return DayCell(
              day: day,
              hasGap: gapDates.contains(dateKey),
              statusDots: statusDotsFor(
                rowsByDate[dateKey] ?? const [],
                colorHexByStatusId,
              ),
            );
          },
        ),
      ),
    );
  }
}
