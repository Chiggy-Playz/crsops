import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:crs_ops/core/employees/repositories/employee_event_repository.dart';

class FakeEmployeeEventRepository implements EmployeeEventRepository {
  FakeEmployeeEventRepository({List<TimelineEntry>? seed}) : _entries = List.of(seed ?? const []);

  final List<TimelineEntry> _entries;
  final List<Map<String, Object?>> addedEvents = [];

  @override
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    addedEvents.add({
      'employeeId': employeeId,
      'eventType': eventType,
      'eventDate': eventDate,
      'note': note,
    });
    _entries.insert(
      0,
      TimelineEntry(employeeId: employeeId, entryDate: eventDate, kind: 'event', label: eventType, note: note),
    );
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String employeeId) async =>
      _entries.where((e) => e.employeeId == employeeId).toList();
}
