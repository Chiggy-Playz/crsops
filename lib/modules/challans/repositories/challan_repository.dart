import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/exception_translator.dart';
import '../../../core/utils/date_time_format.dart';
import '../challan_search.dart';
import '../models/challan.dart';
import '../models/challan_direction.dart';
import '../models/challan_event.dart';
import '../models/challan_item.dart';

/// What the challan form saves. Direction and date are only used when
/// creating; they never change afterwards.
class ChallanDraft {
  const ChallanDraft({
    required this.direction,
    required this.challanDate,
    required this.addressId,
    required this.handledByName,
    this.vehicleNumber,
    this.declaredValue,
    this.notes,
    required this.items,
    this.useLatestAddress = false,
  });

  final ChallanDirection direction;
  final DateTime challanDate;
  final String addressId;

  /// When editing: print the address's newest details instead of the ones
  /// the challan was made with.
  final bool useLatestAddress;
  final String handledByName;
  final String? vehicleNumber;
  final int? declaredValue;
  final String? notes;
  final List<ChallanItem> items;

  List<Map<String, dynamic>> get itemsJson => [
    for (final item in items)
      {
        'description': item.description,
        'additional_description': item.additionalDescription,
        'serial': item.serial,
        'quantity': item.quantity,
        'unit': item.unit,
      },
  ];
}

/// Reads from the `challans` views; every write is a `challans` database
/// function (see the challans migration).
abstract class ChallanRepository {
  /// One direction's challans for one financial year, newest number first.
  Future<List<Challan>> fetchList(ChallanDirection direction, int year);

  /// The financial years that have challans in [direction], newest first.
  Future<List<int>> fetchFinancialYears(ChallanDirection direction);

  /// One challan with its items.
  Future<Challan> fetchById(String id);

  /// A client's challans, both directions, newest first.
  Future<List<Challan>> fetchForClient(String clientId);
  Future<List<ChallanEvent>> fetchHistory(String challanId);

  /// Challans of any financial year matching [filters], newest first, at
  /// most 1000.
  Future<List<Challan>> search(ChallanSearchFilters filters);

  /// [challans] with their items filled in (for the detailed export).
  Future<List<Challan>> withItems(List<Challan> challans);

  /// Names typed before into "Delivered by" / "Received by", most used first.
  Future<List<String>> fetchHandledByNames();

  /// Units typed before, most used first.
  Future<List<String>> fetchUnits();

  /// Returns the new challan's id.
  Future<String> create(ChallanDraft draft);
  Future<void> update(String id, ChallanDraft draft);

  /// Returns the id of the inward challan made when [createReturn] is set.
  Future<String?> cancel(
    String id, {
    String? reason,
    required bool createReturn,
  });
  Future<void> setReceived(String id, DateTime? receivedOn);
  Future<void> setBillNumber(String id, String? billNumber);
  Future<void> setDigitallySigned(String id, {required bool signed});
}

class SupabaseChallanRepository implements ChallanRepository {
  SupabaseChallanRepository(this._client);
  final SupabaseClient _client;

  SupabaseQueryBuilder _from(String table) =>
      _client.schema('challans').from(table);

  Future<dynamic> _rpc(String function, Map<String, dynamic> params) =>
      _client.schema('challans').rpc(function, params: params);

  @override
  Future<List<Challan>> fetchList(ChallanDirection direction, int year) async {
    try {
      final rows = await _from('challan_overview')
          .select()
          .eq('direction', direction.name)
          .eq('financial_year', year)
          .order('number', ascending: false);
      return rows.map(ChallanMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<int>> fetchFinancialYears(ChallanDirection direction) async {
    try {
      final rows = await _from('financial_years')
          .select('financial_year')
          .eq('direction', direction.name)
          .order('financial_year', ascending: false);
      return [for (final row in rows) row['financial_year'] as int];
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Challan> fetchById(String id) async {
    try {
      final results = await Future.wait([
        _from('challan_overview').select().eq('id', id),
        _from('challan_items')
            .select()
            .eq('challan_id', id)
            .order('position', ascending: true),
      ]);
      if (results[0].isEmpty) {
        throw const DataException(
          'That no longer exists. It may have been deleted.',
        );
      }
      final items = results[1].map(ChallanItemMapper.fromMap).toList();
      return ChallanMapper.fromMap(results[0].single).copyWith(items: items);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<Challan>> fetchForClient(String clientId) async {
    try {
      final rows = await _from('challan_overview')
          .select()
          .eq('client_id', clientId)
          .order('challan_date', ascending: false)
          .order('number', ascending: false);
      return rows.map(ChallanMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<ChallanEvent>> fetchHistory(String challanId) async {
    try {
      final rows = await _from('challan_history')
          .select()
          .eq('challan_id', challanId)
          .order('created_at', ascending: false);
      return rows.map(ChallanEventMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<Challan>> search(ChallanSearchFilters filters) async {
    final from = filters.from;
    final to = filters.to;
    final text = filters.text.trim();
    try {
      final rows = await _rpc('search_challans', {
        'p_text': text.isEmpty ? null : text,
        'p_client_ids': filters.clientIds.isEmpty ? null : filters.clientIds,
        'p_from': from == null ? null : dateOnly(from),
        'p_to': to == null ? null : dateOnly(to),
        'p_direction': filters.direction?.name,
      });
      return [
        for (final row in rows as List)
          ChallanMapper.fromMap(row as Map<String, dynamic>),
      ];
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<Challan>> withItems(List<Challan> challans) async {
    // In batches, so the id list stays well inside a request URL.
    const batchSize = 100;
    final itemsByChallan = <String, List<ChallanItem>>{};
    try {
      for (var start = 0; start < challans.length; start += batchSize) {
        final ids = [
          for (final c in challans.skip(start).take(batchSize)) c.id,
        ];
        final rows = await _from('challan_items')
            .select()
            .inFilter('challan_id', ids)
            .order('position', ascending: true);
        for (final row in rows) {
          itemsByChallan
              .putIfAbsent(row['challan_id'] as String, () => [])
              .add(ChallanItemMapper.fromMap(row));
        }
      }
    } catch (error) {
      throw translateException(error);
    }
    return [
      for (final c in challans)
        c.copyWith(items: itemsByChallan[c.id] ?? const []),
    ];
  }

  @override
  Future<List<String>> fetchHandledByNames() async {
    try {
      final rows = await _from('handled_by_names').select('name');
      return [for (final row in rows) row['name'] as String];
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<String>> fetchUnits() async {
    try {
      final rows = await _from('item_units').select('unit');
      return [for (final row in rows) row['unit'] as String];
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<String> create(ChallanDraft draft) async {
    try {
      final id = await _rpc('create_challan', {
        'p_direction': draft.direction.name,
        'p_challan_date': dateOnly(draft.challanDate),
        'p_address_id': draft.addressId,
        'p_handled_by_name': draft.handledByName,
        'p_vehicle_number': draft.vehicleNumber,
        'p_declared_value': draft.declaredValue,
        'p_notes': draft.notes,
        'p_items': draft.itemsJson,
      });
      return id as String;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> update(String id, ChallanDraft draft) async {
    try {
      await _rpc('update_challan', {
        'p_challan_id': id,
        'p_address_id': draft.addressId,
        'p_use_latest_address': draft.useLatestAddress,
        'p_handled_by_name': draft.handledByName,
        'p_vehicle_number': draft.vehicleNumber,
        'p_declared_value': draft.declaredValue,
        'p_notes': draft.notes,
        'p_items': draft.itemsJson,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<String?> cancel(
    String id, {
    String? reason,
    required bool createReturn,
  }) async {
    try {
      final returnId = await _rpc('cancel_challan', {
        'p_challan_id': id,
        'p_reason': reason,
        'p_create_return': createReturn,
      });
      return returnId as String?;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setReceived(String id, DateTime? receivedOn) async {
    try {
      await _rpc('set_received', {
        'p_challan_id': id,
        'p_received_on': receivedOn == null ? null : dateOnly(receivedOn),
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setBillNumber(String id, String? billNumber) async {
    try {
      await _rpc('set_bill_number', {
        'p_challan_id': id,
        'p_bill_number': billNumber,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setDigitallySigned(String id, {required bool signed}) async {
    try {
      await _rpc('set_digitally_signed', {
        'p_challan_id': id,
        'p_signed': signed,
      });
    } catch (error) {
      throw translateException(error);
    }
  }
}
