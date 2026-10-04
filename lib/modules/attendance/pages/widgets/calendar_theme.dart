import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// table_calendar predates Material 3: its default text colours are hardcoded
// light-mode greys (weekday labels #4F4F4F, other-month days #AEAEAE, …) that
// ignore the theme and vanish in dark mode. These swap in theme colours.

DaysOfWeekStyle themedDaysOfWeekStyle(BuildContext context) {
  final theme = Theme.of(context);
  final style = theme.textTheme.labelMedium?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
  return DaysOfWeekStyle(
    weekdayStyle: style ?? const TextStyle(),
    weekendStyle: style ?? const TextStyle(),
  );
}

CalendarStyle themedCalendarStyle(BuildContext context) {
  final dimmed = TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
  );
  return CalendarStyle(outsideTextStyle: dimmed, disabledTextStyle: dimmed);
}
