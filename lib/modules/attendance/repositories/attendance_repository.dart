import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../models/derived_flags_row.dart';
import '../models/effective_status_row.dart';
import '../models/gap_row.dart';

/// Status recorded when a day is marked (e.g. by entering times) without an
/// explicit half status: entering times implies presence. Lives here — not in
/// the UI — so the rule is independent of whichever sheet calls `markDay`.
/// Must match a row in `attendance.status_types` (seeded).
const defaultPresenceStatusId = 'present';

/// Applies [defaultPresenceStatusId] to a null half. Pure so it stays unit
/// testable without a Supabase client.
String applyPresenceDefault(String? halfStatus) =>
    halfStatus ?? defaultPresenceStatusId;

abstract class AttendanceRepository {
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7});
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

  String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

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
              'p_start': _dateOnly(start),
              'p_end': _dateOnly(end),
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
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7}) async {
    try {
      final rows = await _client
          .schema('attendance')
          .rpc('recent_gaps', params: {'p_window_days': windowDays});
      return (rows as List)
          .map((r) => GapRowMapper.fromMap(r as Map<String, dynamic>))
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
              'p_start': _dateOnly(start),
              'p_end': _dateOnly(end),
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
      await _client.schema('attendance').from('attendance_days').upsert({
        'employee_id': employeeId,
        'date': _dateOnly(date),
        'first_half_status': applyPresenceDefault(firstHalfStatus),
        'second_half_status': applyPresenceDefault(secondHalfStatus),
        'time_in': timeIn,
        'time_out': timeOut,
        'note': note,
      }, onConflict: 'employee_id,date');
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> markAllPresent({
    required DateTime date,
    required List<String> employeeIds,
  }) async {
    try {
      final rows = employeeIds
          .map(
            (id) => {
              'employee_id': id,
              'date': _dateOnly(date),
              'first_half_status': 'present',
              'second_half_status': 'present',
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
  Future<void> markHoliday({
    required DateTime date,
    required List<String> employeeIds,
  }) async {
    try {
      final rows = employeeIds
          .map(
            (id) => {
              'employee_id': id,
              'date': _dateOnly(date),
              'first_half_status': 'holiday',
              'second_half_status': 'holiday',
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
          .eq('date', _dateOnly(date));
    } catch (error) {
      throw translateException(error);
    }
  }
}
