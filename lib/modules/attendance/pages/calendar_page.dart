import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

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
    final gapDates = gapsAsync.value?.map((g) => g.date.toIso8601String().split('T').first).toSet() ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reports',
            onPressed: () => Navigator.of(context).pushNamed('/reports'),
          ),
        ],
      ),
      body: TableCalendar(
        firstDay: DateTime(2000, 1, 1),
        lastDay: DateTime(2100, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        onPageChanged: (day) => setState(() => _focusedDay = day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay = focusedDay);
          Navigator.of(context).pushNamed(
            '/attendance/${selectedDay.toIso8601String().split('T').first}',
          );
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => DayCell(
            day: day,
            hasGap: gapDates.contains(day.toIso8601String().split('T').first),
          ),
        ),
      ),
    );
  }
}
