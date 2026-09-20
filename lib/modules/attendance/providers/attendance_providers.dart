import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/supabase_client_provider.dart';
import '../models/derived_flags_row.dart';
import '../models/effective_status_row.dart';
import '../models/gap_row.dart';
import '../models/shift_defaults.dart';
import '../models/status_type.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/shift_defaults_repository.dart';
import '../repositories/status_type_repository.dart';

part 'attendance_providers.g.dart';

@Riverpod(keepAlive: true)
ShiftDefaultsRepository shiftDefaultsRepository(Ref ref) =>
    SupabaseShiftDefaultsRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
StatusTypeRepository statusTypeRepository(Ref ref) =>
    SupabaseStatusTypeRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) =>
    SupabaseAttendanceRepository(ref.watch(supabaseClientProvider));

@riverpod
Future<List<ShiftDefaults>> shiftDefaultsHistory(Ref ref) =>
    ref.watch(shiftDefaultsRepositoryProvider).fetchHistory();

@Riverpod(keepAlive: true)
Future<List<StatusType>> statusTypes(Ref ref) =>
    ref.watch(statusTypeRepositoryProvider).fetchAll();

@riverpod
Future<List<EffectiveStatusRow>> effectiveRangeStatus(
  Ref ref, {
  required DateTime start,
  required DateTime end,
  String? employeeId,
}) => ref
    .watch(attendanceRepositoryProvider)
    .fetchEffectiveRangeStatus(start: start, end: end, employeeId: employeeId);

@riverpod
Future<List<GapRow>> recentGaps(Ref ref) =>
    ref.watch(attendanceRepositoryProvider).fetchRecentGaps();

@riverpod
Future<List<DerivedFlagsRow>> derivedFlags(
  Ref ref, {
  required DateTime start,
  required DateTime end,
  String? employeeId,
}) => ref
    .watch(attendanceRepositoryProvider)
    .fetchDerivedFlags(start: start, end: end, employeeId: employeeId);
