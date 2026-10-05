import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../../../core/utils/date_key.dart';
import '../models/derived_flags_row.dart';
import '../models/effective_status_row.dart';

/// Status recorded when a day is marked (e.g. by entering times) without an
/// explicit half status: entering times implies presence. Lives here — not in
/// the UI — so the rule is independent of whichever sheet calls `markDay`.
/// Must match a row in `attendance.status_types` (seeded).
const defaultPresenceStatusId = 'present';

/// Seeded `attendance.status_types` id used by the mark-as-holiday bulk
/// action. Named next to [defaultPresenceStatusId] so a DB rename breaks
/// loudly in one place instead of silently in a string literal.
const holidayStatusId = 'holiday';

/// Applies [defaultPresenceStatusId] to a null half. Pure so it stays unit
/// testable without a Supabase client.
String applyPresenceDefault(String? halfStatus) =>
    halfStatus ?? defaultPresenceStatusId;

/// The exact upsert payload [SupabaseAttendanceRepository.markDay] writes.
/// Pure so upsert shape and presence-default application stay unit tested
/// without a Supabase client; `date` is already date-only (yyyy-MM-dd).
Map<String, dynamic> markDayPayload({
  required String employeeId,
  required String date,
  String? firstHalfStatus,
  String? secondHalfStatus,
  String? timeIn,
  String? timeOut,
  String? note,
}) => {
  'employee_id': employeeId,
  'date': date,
  'first_half_status': applyPresenceDefault(firstHalfStatus),
  'second_half_status': applyPresenceDefault(secondHalfStatus),
  'time_in': timeIn,
  'time_out': timeOut,
  'note': note,
};

abstract class AttendanceRepository {
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });

  /// Explicit per-employee marking for one date — full-day tap-to-present sets
  /// both halves to the same status; the half-split UI can call this with
  /// different first/second half values.
  Future<void> markDay({
    required String employeeId,
    required DateTime date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  });

  /// Bulk action: marks every active employee present (both halves) for [date].
  /// Overwrites any existing explicit marking for that date — the UI gates this
  /// behind a confirm dialog.
  Future<void> markAllPresent({
    required DateTime date,
    required List<String> employeeIds,
  });

  /// Bulk action: marks every active employee's day as a company holiday (both
  /// halves) for [date]. Same overwrite/confirm-dialog caveat as markAllPresent.
  Future<void> markHoliday({
    required DateTime date,
    required List<String> employeeIds,
  });

  /// Clears an explicit mark entirely — deletes the row so the day goes back
  /// to computed-unmarked/week-off, rather than setting some "blank" status.
  Future<void> unmarkDay({required String employeeId, required DateTime date});
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    try {
      final rows = await _client
          .schema('attendance')
          .rpc(
            'effective_range_status',
            params: {
              'p_start': dateOnly(start),
              'p_end': dateOnly(end),
              'p_employee_id': employeeId,
            },
          );
      return (rows as List)
          .map(
            (r) => EffectiveStatusRowMapper.fromMap(r as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    try {
      final rows = await _client
          .schema('attendance')
          .rpc(
            'derived_flags',
            params: {
              'p_start': dateOnly(start),
              'p_end': dateOnly(end),
              'p_employee_id': employeeId,
            },
          );
      return (rows as List)
          .map((r) => DerivedFlagsRowMapper.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markDay({
    required String employeeId,
    required DateTime date,
    String? firstHalfStatus,
    String? secondHalfStatus,
    String? timeIn,
    String? timeOut,
    String? note,
  }) async {
    try {
      await _client
          .schema('attendance')
          .from('attendance_days')
          .upsert(
            markDayPayload(
              employeeId: employeeId,
              date: dateOnly(date),
              firstHalfStatus: firstHalfStatus,
              secondHalfStatus: secondHalfStatus,
              timeIn: timeIn,
              timeOut: timeOut,
              note: note,
            ),
            onConflict: 'employee_id,date',
          );
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markAllPresent({
    required DateTime date,
    required List<String> employeeIds,
  }) async {
    await _markAll(
      date: date,
      employeeIds: employeeIds,
      status: defaultPresenceStatusId,
    );
  }

  @override
  Future<void> markHoliday({
    required DateTime date,
    required List<String> employeeIds,
  }) async {
    await _markAll(
      date: date,
      employeeIds: employeeIds,
      status: holidayStatusId,
    );
  }

  /// Shared bulk-mark body behind [markAllPresent]/[markHoliday], which
  /// differ only by status id.
  Future<void> _markAll({
    required DateTime date,
    required List<String> employeeIds,
    required String status,
  }) async {
    try {
      final rows = employeeIds
          .map(
            (id) => {
              'employee_id': id,
              'date': dateOnly(date),
              'first_half_status': status,
              'second_half_status': status,
            },
          )
          .toList();
      await _client
          .schema('attendance')
          .from('attendance_days')
          .upsert(rows, onConflict: 'employee_id,date');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> unmarkDay({
    required String employeeId,
    required DateTime date,
  }) async {
    try {
      await _client
          .schema('attendance')
          .from('attendance_days')
          .delete()
          .eq('employee_id', employeeId)
          .eq('date', dateOnly(date));
    } catch (error) {
      throw translateException(error);
    }
  }
}
