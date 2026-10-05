import 'package:flutter/material.dart';

import '../../core/utils/date_key.dart';
import '../../core/widgets/status_metadata.dart';
import 'day_status.dart';
import 'models/effective_status_row.dart';
import 'models/status_type.dart';

/// Groups rows by date (`yyyy-MM-dd` key) — shared by any calendar view that
/// needs "what happened on this day" regardless of how many employees' rows
/// are in the list (one, a chosen few, or all of them).
Map<String, List<EffectiveStatusRow>> groupRowsByDate(
  List<EffectiveStatusRow> rows,
) {
  final byDate = <String, List<EffectiveStatusRow>>{};
  for (final row in rows) {
    byDate.putIfAbsent(dateOnly(row.date), () => []).add(row);
  }
  return byDate;
}

/// One dot color per distinct status represented among `dayRows` — a mixed
/// day (some present, some absent) naturally gets multiple dots instead of
/// needing a single "winning" fill color, which sidesteps the "how does a
/// mixed day roll up" open question entirely rather than answering it.
/// Skips unmarked, non-week-off rows (no status to show); uses each row's
/// first-half status as its representative status, same simplification
/// already used by report_calculations.dart's summary buckets.
///
/// isWeekOff is a property of the date (every row on a Sunday has it true),
/// not of whether that employee has an explicit mark — an explicit mark
/// must win over it, same priority order as computeStatusSummary, or an
/// employee explicitly marked present on a week-off day silently loses
/// their dot to the week-off one.
List<Color> statusDotsFor(
  List<EffectiveStatusRow> dayRows,
  Map<String, String> colorHexByStatusId,
) {
  // Always in status display order (Present first, …) so dots line up
  // across days instead of following whatever order the rows came back in.
  final statusIds =
      {for (final row in dayRows) ?representativeStatus(row)}.toList()
        ..sort((a, b) => statusDisplayRank(a).compareTo(statusDisplayRank(b)));
  return [for (final id in statusIds) colorFor(colorHexByStatusId[id])];
}

/// Screen-reader summary of a day's statuses, in display order — e.g.
/// "3 Present, 1 Absent". Null when nothing is marked.
String? statusSummaryLabel(
  List<EffectiveStatusRow> dayRows,
  Map<String, String> labelByStatusId,
) {
  final counts = <String, int>{};
  for (final row in dayRows) {
    final statusId = representativeStatus(row);
    if (statusId != null) counts[statusId] = (counts[statusId] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final ids = counts.keys.toList()
    ..sort((a, b) => statusDisplayRank(a).compareTo(statusDisplayRank(b)));
  return [for (final id in ids) '${counts[id]} ${labelByStatusId[id] ?? id}']
      .join(', ');
}

/// The gap rule (same as the server's attendance.recent_gaps): some active
/// employee has no mark on a working day that's already past. Today and
/// later can't be "missed" yet.
bool hasUnmarkedPastDay(List<EffectiveStatusRow> dayRows, DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (!DateTime(day.year, day.month, day.day).isBefore(today)) return false;
  return dayRows.any((row) => !row.isExplicit && !row.isWeekOff);
}
