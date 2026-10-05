import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';

// ── Shown to the user ───────────────────────────────────────────────────────

final _displayDate = DateFormat('d MMM yyyy');

/// A date as shown everywhere in the app: "6 Oct 2026".
String formatDisplayDate(DateTime date) => _displayDate.format(date);

// ── Stored in the database ──────────────────────────────────────────────────

/// Date-only key (`yyyy-MM-dd`) for a [DateTime], used for PostgREST date
/// columns, provider keys, and calendar grouping. The truncation uses the
/// DateTime's own (local) zone.
String dateOnly(DateTime date) => date.toIso8601String().split('T').first;

/// A time as written to a Postgres `time` column: `"HH:mm"`.
String toStoredTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Parses `"HH:mm"` (write format) and `"HH:mm:ss"` (Postgres read-back).
/// Returns null for anything else, including out-of-range values from a bad
/// migration or manual DB edit, so callers fall back instead of crashing
/// TimeOfDay's asserts.
TimeOfDay? parseStoredTime(String? stored) {
  if (stored == null) return null;
  final parts = stored.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}
