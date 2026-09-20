import 'models/effective_status_row.dart';

/// The single shared "which status represents this row" rule: an explicit
/// mark wins with its first-half status, otherwise a week-off date reports
/// `week_off`, otherwise there is no status (unmarked working day).
/// Used by both the report summary buckets and the calendar dots so the two
/// can never disagree on priority — only on what they do with the answer
/// (count vs. dot).
String? representativeStatus(EffectiveStatusRow row) =>
    row.isExplicit ? row.firstHalfStatus : (row.isWeekOff ? 'week_off' : null);
