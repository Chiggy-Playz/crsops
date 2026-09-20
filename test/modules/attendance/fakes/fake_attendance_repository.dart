import 'package:crs_ops/modules/attendance/models/derived_flags_row.dart';
import 'package:crs_ops/modules/attendance/models/effective_status_row.dart';
import 'package:crs_ops/modules/attendance/models/gap_row.dart';
import 'package:crs_ops/modules/attendance/repositories/attendance_repository.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({
    List<EffectiveStatusRow>? rangeStatusSeed,
    List<GapRow>? gapsSeed,
    List<DerivedFlagsRow>? derivedFlagsSeed,
  })  : _rangeStatus = List.of(rangeStatusSeed ?? const []),
        _gaps = List.of(gapsSeed ?? const []),
        _derivedFlags = List.of(derivedFlagsSeed ?? const []);

  final List<EffectiveStatusRow> _rangeStatus;
  final List<GapRow> _gaps;
  final List<DerivedFlagsRow> _derivedFlags;

  final List<Map<String, Object?>> markedDays = [];
  final List<DateTime> markedAllPresentDates = [];
  final List<DateTime> markedHolidayDates = [];

  @override
  Future<List<EffectiveStatusRow>> fetchEffectiveRangeStatus({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async =>
      _rangeStatus
          .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
          .where((r) => employeeId == null || r.employeeId == employeeId)
          .toList();

  @override
  Future<List<GapRow>> fetchRecentGaps({int windowDays = 7}) async => List.of(_gaps);

  @override
  Future<List<DerivedFlagsRow>> fetchDerivedFlags({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async =>
      _derivedFlags
          .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
          .where((r) => employeeId == null || r.employeeId == employeeId)
          .toList();

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
    markedDays.add({
      'employeeId': employeeId,
      'date': date,
      'firstHalfStatus': firstHalfStatus,
      'secondHalfStatus': secondHalfStatus,
      'timeIn': timeIn,
      'timeOut': timeOut,
      'note': note,
    });
  }

  @override
  Future<void> markAllPresent({required DateTime date, required List<String> employeeIds}) async {
    markedAllPresentDates.add(date);
  }

  @override
  Future<void> markHoliday({required DateTime date, required List<String> employeeIds}) async {
    markedHolidayDates.add(date);
  }

  final List<Map<String, Object?>> unmarkedDays = [];

  @override
  Future<void> unmarkDay({required String employeeId, required DateTime date}) async {
    unmarkedDays.add({'employeeId': employeeId, 'date': date});
  }
}
