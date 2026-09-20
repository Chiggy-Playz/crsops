import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../../utils/date_key.dart';
import '../models/timeline_entry.dart';

abstract class EmployeeEventRepository {
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  });
  Future<List<TimelineEntry>> fetchTimeline(String employeeId);

  /// Needed for real cases like backfilling a long-tenured employee's actual
  /// historical join date when first setting up the app — not just fixing
  /// typos.
  Future<void> updateEvent({
    required String id,
    required String eventType,
    required DateTime eventDate,
    String? note,
  });
  Future<void> deleteEvent(String id);
}

class SupabaseEmployeeEventRepository implements EmployeeEventRepository {
  SupabaseEmployeeEventRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> addEvent({
    required String employeeId,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    try {
      await _client.schema('core').from('employee_events').insert({
        'employee_id': employeeId,
        'event_type': eventType,
        'event_date': dateOnly(eventDate),
        'note': note,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<TimelineEntry>> fetchTimeline(String employeeId) async {
    try {
      final rows = await _client
          .schema('core')
          .from('employee_timeline')
          .select()
          .eq('employee_id', employeeId)
          .order('entry_date', ascending: false);
      return rows.map(TimelineEntryMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> updateEvent({
    required String id,
    required String eventType,
    required DateTime eventDate,
    String? note,
  }) async {
    try {
      await _client
          .schema('core')
          .from('employee_events')
          .update({
            'event_type': eventType,
            'event_date': dateOnly(eventDate),
            'note': note,
          })
          .eq('id', id);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await _client
          .schema('core')
          .from('employee_events')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw translateException(error);
    }
  }
}
