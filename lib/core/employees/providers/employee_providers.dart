import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/supabase_client_provider.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../repositories/employee_event_repository.dart';
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

@riverpod
Future<List<Employee>> employeeList(Ref ref) => ref.watch(employeeRepositoryProvider).fetchAll();

@riverpod
Future<Employee> employee(Ref ref, String employeeId) =>
    ref.watch(employeeRepositoryProvider).fetchById(employeeId);

@riverpod
Future<String?> employeeCurrentStatus(Ref ref, String employeeId) =>
    ref.watch(employeeRepositoryProvider).fetchCurrentStatus(employeeId);

@riverpod
Future<List<TimelineEntry>> employeeTimeline(Ref ref, String employeeId) =>
    ref.watch(employeeEventRepositoryProvider).fetchTimeline(employeeId);

@Riverpod(keepAlive: true)
Future<List<EventType>> eventTypes(Ref ref) => ref.watch(eventTypeRepositoryProvider).fetchAll();
