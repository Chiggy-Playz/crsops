import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../../errors/exception_translator.dart';
import '../models/client.dart';
import '../models/client_address.dart';
import '../models/indian_state.dart';

/// Client rows with each one's [Client.addresses] filled in from
/// `current_client_addresses` rows, sorted by label. Pure so the merge stays
/// unit tested without a Supabase client.
List<Client> clientsWithAddresses(
  List<Map<String, dynamic>> clientRows,
  List<Map<String, dynamic>> addressRows,
) {
  final addressesByClient = <String, List<ClientAddress>>{};
  for (final row in addressRows) {
    final address = ClientAddressMapper.fromMap(row);
    addressesByClient.putIfAbsent(address.clientId, () => []).add(address);
  }
  for (final addresses in addressesByClient.values) {
    addresses.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  }
  return [
    for (final row in clientRows)
      ClientMapper.fromMap(row)
          .copyWith(addresses: addressesByClient[row['id']] ?? const []),
  ];
}

/// Every write goes through a `core` database function: the app can only
/// read the client tables (see the clients migration for why).
abstract class ClientRepository {
  /// Every client by name, archived ones included, each with its addresses.
  Future<List<Client>> fetchAll();
  Future<Client> fetchById(String id);
  Future<List<IndianState>> fetchStates();

  /// Creates the client with its first address. Returns the new client's id.
  Future<String> create({
    required String name,
    String? notes,
    required String label,
    required String nameOnChallan,
    required String address,
    required String stateCode,
    String? gstin,
  });
  Future<void> update({
    required String id,
    required String name,
    String? notes,
  });
  Future<void> setArchived(String id, {required bool archived});
  Future<void> delete(String id);

  /// Adds an address when [addressId] is null, otherwise saves changes to it.
  Future<void> saveAddress({
    String? addressId,
    required String clientId,
    required String label,
    required String nameOnChallan,
    required String address,
    required String stateCode,
    String? gstin,
  });
  Future<void> setAddressArchived(String addressId, {required bool archived});
  Future<void> deleteAddress(String addressId);
}

class SupabaseClientRepository implements ClientRepository {
  SupabaseClientRepository(this._client);
  final SupabaseClient _client;

  SupabaseQueryBuilder _from(String table) =>
      _client.schema('core').from(table);

  Future<dynamic> _rpc(String function, Map<String, dynamic> params) =>
      _client.schema('core').rpc(function, params: params);

  @override
  Future<List<Client>> fetchAll() async {
    try {
      final results = await Future.wait([
        _from('clients').select().order('name', ascending: true),
        _from('current_client_addresses').select(),
      ]);
      return clientsWithAddresses(results[0], results[1]);
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<Client> fetchById(String id) async {
    try {
      final results = await Future.wait([
        _from('clients').select().eq('id', id),
        _from('current_client_addresses').select().eq('client_id', id),
      ]);
      if (results[0].isEmpty) {
        throw const DataException(
          'That no longer exists. It may have been deleted.',
        );
      }
      return clientsWithAddresses(results[0], results[1]).single;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<List<IndianState>> fetchStates() async {
    try {
      final rows = await _from('indian_states')
          .select()
          .order('name', ascending: true);
      return rows.map(IndianStateMapper.fromMap).toList();
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<String> create({
    required String name,
    String? notes,
    required String label,
    required String nameOnChallan,
    required String address,
    required String stateCode,
    String? gstin,
  }) async {
    try {
      final id = await _rpc('create_client', {
        'p_name': name,
        'p_notes': notes,
        'p_label': label,
        'p_name_on_challan': nameOnChallan,
        'p_address': address,
        'p_state_code': stateCode,
        'p_gstin': gstin,
      });
      return id as String;
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    String? notes,
  }) async {
    try {
      await _rpc('update_client', {
        'p_client_id': id,
        'p_name': name,
        'p_notes': notes,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    try {
      await _rpc('set_client_archived', {
        'p_client_id': id,
        'p_archived': archived,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _rpc('delete_client', {'p_client_id': id});
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> saveAddress({
    String? addressId,
    required String clientId,
    required String label,
    required String nameOnChallan,
    required String address,
    required String stateCode,
    String? gstin,
  }) async {
    try {
      await _rpc('save_client_address', {
        'p_address_id': addressId,
        'p_client_id': clientId,
        'p_label': label,
        'p_name_on_challan': nameOnChallan,
        'p_address': address,
        'p_state_code': stateCode,
        'p_gstin': gstin,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> setAddressArchived(
    String addressId, {
    required bool archived,
  }) async {
    try {
      await _rpc('set_client_address_archived', {
        'p_address_id': addressId,
        'p_archived': archived,
      });
    } catch (error) {
      throw translateException(error);
    }
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    try {
      await _rpc('delete_client_address', {'p_address_id': addressId});
    } catch (error) {
      throw translateException(error);
    }
  }
}
