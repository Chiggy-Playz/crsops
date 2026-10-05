import 'package:crs_ops/core/employees/models/timeline_entry.dart';
import 'package:crs_ops/core/employees/repositories/employee_event_repository.dart';

class FakeEmployeeEventRepository implements EmployeeEventRepository {
  FakeEmployeeEventRepository({List<TimelineEntry>? seed})
    : _entries = List.of(seed ?? const []);

  final List<TimelineEntry> _entries;
  final List<Map<String, Object?>> addedEvents = [];
  final List<String> deletedIds = [];
  int _nextId = 1;

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
      TimelineEntry(
        id: 'fake-event-${_nextId++}',
        employeeId: employeeId,
        entryDate: eventDate,
        kind: 'event',
        label: eventType,
        note: note,
      ),
    );
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String employeeId) async =>
      _entries.where((e) => e.employeeId == employeeId).toList();

  @override
  Future<void> updateEvent({
    required String id,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    final index = _entries.indexWhere((e) => e.id == id);
    _entries[index] = _entries[index].copyWith(
      label: eventType,
      entryDate: eventDate,
      note: note,
    );
  }

  @override
  Future<void> deleteEvent(String id) async {
    deletedIds.add(id);
    _entries.removeWhere((e) => e.id == id);
  }
}
