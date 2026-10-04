import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/exception_translator.dart';
import '../../utils/date_key.dart';

abstract class EmployeeLedgerEntryRepository {
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  });

  /// Powers the "Add payment" dialog's dropdown — typo-safety without a
  /// lookup table, per the design: pick an existing value rather than
  /// retype it, or type a genuinely new one (see the dialog).
  Future<List<String>> fetchDistinctEntryTypes();

  Future<void> updateEntry({
    required String id,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  });
  Future<void> deleteEntry(String id);
}

class SupabaseEmployeeLedgerEntryRepository
    implements EmployeeLedgerEntryRepository {
  SupabaseEmployeeLedgerEntryRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<void> addEntry({
    required String employeeId,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    try {
      await _client.schema('core').from('employee_ledger_entries').insert({
        'employee_id': employeeId,
        'entry_date': dateOnly(entryDate),
        'amount': amount,
        'entry_type': entryType,
        'note': note,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<String>> fetchDistinctEntryTypes() async {
    try {
      final rows = await _client
          .schema('core')
          .from('employee_ledger_entries')
          .select('entry_type')
          .order('entry_type', ascending: true);
      final types = rows.map((r) => r['entry_type'] as String).toSet().toList()
        ..sort();
      return types;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> updateEntry({
    required String id,
    required DateTime entryDate,
    required double amount,
    required String entryType,
    String? note,
  }) async {
    try {
      await _client
          .schema('core')
          .from('employee_ledger_entries')
          .update({
            'entry_date': dateOnly(entryDate),
            'amount': amount,
            'entry_type': entryType,
            'note': note,
          })
          .eq('id', id);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      await _client
          .schema('core')
          .from('employee_ledger_entries')
          .delete()
          .eq('id', id);
    } catch (error) {
      throw translateException(error);
    }
  }
}
