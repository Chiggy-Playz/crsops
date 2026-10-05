import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../models/status_type.dart';

abstract class StatusTypeRepository {
  Future<List<StatusType>> fetchAll();
  Future<StatusType> add({
    required String id,
    required String label,
    String? iconName,
    String? colorHex,
  });
  Future<StatusType> updateDisplay(
    String id, {
    String? iconName,
    String? colorHex,
  });
}

class SupabaseStatusTypeRepository implements StatusTypeRepository {
  SupabaseStatusTypeRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<StatusType>> fetchAll() async {
    try {
      final rows = await _client
          .schema('attendance')
          .from('status_types')
          .select()
          .order('id', ascending: true);
      return rows.map(StatusTypeMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<StatusType> add({
    required String id,
    required String label,
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('status_types')
          .insert({
            'id': id,
            'label': label,
            'icon_name': iconName,
            'color_hex': colorHex,
          })
          .select()
          .single();
      return StatusTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<StatusType> updateDisplay(
    String id, {
    String? iconName,
    String? colorHex,
  }) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('status_types')
          .update({'icon_name': iconName, 'color_hex': colorHex})
          .eq('id', id)
          .select()
          .single();
      return StatusTypeMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
