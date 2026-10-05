import 'package:flutter/material.dart';

import 'day_status.dart';
import 'models/derived_flags_row.dart';
import 'models/effective_status_row.dart';
import 'models/status_type.dart';

const _unmarkedKey = 'unmarked';

/// Open product question, deliberately not resolved here (see plan.md): a
/// mixed first-half-present/second-half-absent day counts only toward
/// first_half_status's bucket — second_half_status is not counted
/// separately. Real, working v1 behavior with a known, stated limitation.
Map<String, int> computeStatusSummary(
  List<EffectiveStatusRow> rows,
  List<StatusType> statusTypes,
) {
  final summary = <String, int>{
    for (final t in statusTypes) t.id: 0,
    _unmarkedKey: 0,
  };

  for (final row in rows) {
    final bucket = representativeStatus(row) ?? _unmarkedKey;
    summary[bucket] = (summary[bucket] ?? 0) + 1;
  }

  return summary;
}

List<DerivedFlagsRow> filterExceptions(List<DerivedFlagsRow> rows) =>
    rows.where((r) => r.isLate || r.isEarly || r.overtimeMinutes > 0).toList();

/// Overtime display: minutes below an hour ("45m"), hours at/above it
/// ("2h", "1h 30m"). Pure display — the stored minute count is untouched.
/// Callers only pass positive flag values; the assert pins that contract.
String formatOvertime(int totalMinutes) {
  assert(totalMinutes >= 0, 'overtime minutes must not be negative');
  if (totalMinutes < 60) return '${totalMinutes}m';
  final hours = totalMinutes ~/ 60;
  final rest = totalMinutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

/// The whole of last month: the 1st to its last day. Day 0 of a month is the
/// last day of the one before, and month 0 rolls back to December of the
/// previous year, so January needs no special case.
DateTimeRange previousMonthRange(DateTime now) => DateTimeRange(
  start: DateTime(now.year, now.month - 1, 1),
  end: DateTime(now.year, now.month, 0),
);
