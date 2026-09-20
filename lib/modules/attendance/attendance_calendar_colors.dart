import 'package:flutter/material.dart';

import '../../core/widgets/status_metadata.dart';
import 'models/effective_status_row.dart';

/// Groups rows by date (`yyyy-MM-dd` key) — shared by any calendar view that
/// needs "what happened on this day" regardless of how many employees' rows
/// are in the list (one, a chosen few, or all of them).
Map<String, List<EffectiveStatusRow>> groupRowsByDate(List<EffectiveStatusRow> rows) {
  final byDate = <String, List<EffectiveStatusRow>>{};
  for (final row in rows) {
    byDate.putIfAbsent(row.date.toIso8601String().split('T').first, () => []).add(row);
  }
  return byDate;
}

/// Only the two unambiguous cases get a fill color: every included employee
/// week-off that day, or every included employee explicitly marked the same
/// single status. A genuinely mixed day (some present, some absent, some
/// unmarked) is left uncolored — plan.md explicitly leaves "how does a mixed
/// day roll up" as an open product question for reports; inventing an answer
/// here isn't this fix's call to make. Works the same whether `dayRows` has
/// one employee's row or many — a single row trivially satisfies "every row
/// agrees."
Color? summaryColorFor(List<EffectiveStatusRow> dayRows, Map<String, String> colorHexByStatusId) {
  if (dayRows.isEmpty) return null;

  if (dayRows.every((r) => r.isWeekOff)) {
    return colorFor(colorHexByStatusId['week_off']);
  }

  if (dayRows.every((r) => r.isExplicit)) {
    final firstStatus = dayRows.first.firstHalfStatus;
    final uniform = dayRows.every((r) => r.firstHalfStatus == firstStatus && r.secondHalfStatus == firstStatus);
    if (uniform && firstStatus != null) {
      return colorFor(colorHexByStatusId[firstStatus]);
    }
  }

  return null;
}
