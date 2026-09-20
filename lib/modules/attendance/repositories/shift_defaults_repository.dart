import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exception_translator.dart';
import '../../../core/utils/date_key.dart';
import '../models/shift_defaults.dart';

abstract class ShiftDefaultsRepository {
  Future<List<ShiftDefaults>> fetchHistory();
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  });
}

class SupabaseShiftDefaultsRepository implements ShiftDefaultsRepository {
  SupabaseShiftDefaultsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ShiftDefaults>> fetchHistory() async {
    try {
      final rows = await _client
          .schema('attendance')
          .from('shift_defaults')
          .select()
          .order('effective_from', ascending: false);
      return rows.map(ShiftDefaultsMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<ShiftDefaults> addEffectiveFrom({
    required DateTime effectiveFrom,
    required String defaultStart,
    required String defaultEnd,
    required List<int> weekOffDays,
  }) async {
    try {
      final row = await _client
          .schema('attendance')
          .from('shift_defaults')
          .insert({
            'effective_from': dateOnly(effectiveFrom),
            'default_start': defaultStart,
            'default_end': defaultEnd,
            'week_off_days': weekOffDays,
          })
          .select()
          .single();
      return ShiftDefaultsMapper.fromMap(row);
    } catch (error) {
      throw translateException(error);
    }
  }
}
