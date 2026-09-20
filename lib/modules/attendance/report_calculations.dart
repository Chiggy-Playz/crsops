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
    final String bucket;
    if (row.isExplicit) {
      bucket = row.firstHalfStatus ?? _unmarkedKey;
    } else if (row.isWeekOff) {
      bucket = 'week_off';
    } else {
      bucket = _unmarkedKey;
    }
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
