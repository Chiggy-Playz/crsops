import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../repositories/employee_event_repository.dart';
import '../repositories/employee_ledger_entry_repository.dart';
import '../repositories/employee_repository.dart';
import '../repositories/event_type_repository.dart';

part 'employee_providers.g.dart';

@Riverpod(keepAlive: true)
EmployeeRepository employeeRepository(Ref ref) =>
    SupabaseEmployeeRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
EmployeeEventRepository employeeEventRepository(Ref ref) =>
    SupabaseEmployeeEventRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
EventTypeRepository eventTypeRepository(Ref ref) =>
    SupabaseEventTypeRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
EmployeeLedgerEntryRepository employeeLedgerEntryRepository(Ref ref) =>
    SupabaseEmployeeLedgerEntryRepository(ref.watch(supabaseClientProvider));

/// Goes up by one whenever an employee's joined/left history changes:
/// creating an employee, or adding, editing or deleting one of their events.
/// Everything derived from that history (employees' status, the timeline,
/// and attendance's who-was-employed-on-which-day data) watches this, so one
/// [EmployeeHistoryRevision.bump] refreshes all of it.
@Riverpod(keepAlive: true)
class EmployeeHistoryRevision extends _$EmployeeHistoryRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

@riverpod
Future<List<Employee>> employeeList(Ref ref) {
  ref.watch(employeeHistoryRevisionProvider);
  return ref.watch(employeeRepositoryProvider).fetchAll();
}

@riverpod
Future<Employee> employee(Ref ref, String employeeId) {
  ref.watch(employeeHistoryRevisionProvider);
  return ref.watch(employeeRepositoryProvider).fetchById(employeeId);
}

@riverpod
Future<List<TimelineEntry>> employeeTimeline(Ref ref, String employeeId) {
  ref.watch(employeeHistoryRevisionProvider);
  return ref.watch(employeeEventRepositoryProvider).fetchTimeline(employeeId);
}

@Riverpod(keepAlive: true)
Future<List<EventType>> eventTypes(Ref ref) =>
    ref.watch(eventTypeRepositoryProvider).fetchAll();

@Riverpod(keepAlive: true)
Future<List<String>> distinctEntryTypes(Ref ref) =>
    ref.watch(employeeLedgerEntryRepositoryProvider).fetchDistinctEntryTypes();
