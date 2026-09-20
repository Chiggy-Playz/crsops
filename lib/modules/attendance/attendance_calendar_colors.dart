import 'package:flutter/material.dart';

import '../../core/utils/date_key.dart';
import '../../core/widgets/status_metadata.dart';
import 'day_status.dart';
import 'models/effective_status_row.dart';

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
  final seen = <String>{};
  final dots = <Color>[];
  for (final row in dayRows) {
    final statusId = representativeStatus(row);
    if (statusId == null) continue;
    if (seen.add(statusId)) {
      dots.add(colorFor(colorHexByStatusId[statusId]));
    }
  }
  return dots;
}
