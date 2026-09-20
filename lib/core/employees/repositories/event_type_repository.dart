import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../models/event_type.dart';

abstract class EventTypeRepository {
  Future<List<EventType>> fetchAll();

  /// Self-service: any admin-or-above types a brand-new descriptive label from
  /// the "Add event" dialog. Always inserts with status_effect/icon_name/color_hex
  /// null — structural (active/inactive) types are seeded by migration only.
  Future<EventType> addDescriptiveType(String id, {String? description});

  /// Superadmin-only in the UI (see event_types_manager_page.dart) — icon/color
  /// edit on any existing type.
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex});
}

class SupabaseEventTypeRepository implements EventTypeRepository {
  SupabaseEventTypeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<EventType>> fetchAll() async {
    try {
      final rows = await _client.schema('core').from('event_types').select().order('id');
      return rows.map(EventTypeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<EventType> addDescriptiveType(String id, {String? description}) async {
    try {
      final row = await _client
          .schema('core')
          .from('event_types')
          .insert({'id': id, 'description': description})
          .select()
          .single();
      return EventTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<EventType> updateDisplay(String id, {String? iconName, String? colorHex}) async {
    try {
      final row = await _client
          .schema('core')
          .from('event_types')
          .update({'icon_name': iconName, 'color_hex': colorHex})
          .eq('id', id)
          .select()
          .single();
      return EventTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
