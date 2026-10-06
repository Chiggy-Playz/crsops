import 'package:crs_ops/core/clients/models/client.dart';
import 'package:crs_ops/core/clients/models/client_address.dart';
import 'package:crs_ops/core/clients/models/indian_state.dart';
import 'package:crs_ops/core/clients/repositories/client_repository.dart';

/// In-memory clients. Addresses are replaced in place on save (the fake
/// doesn't model versions), which is all the UI tests need.
class FakeClientRepository implements ClientRepository {
  FakeClientRepository({List<Client>? seed})
    : _clients = List.of(seed ?? const []);

  final List<Client> _clients;

  static const states = [
    IndianState(code: '06', name: 'Haryana'),
    IndianState(code: '07', name: 'Delhi'),
  ];

  static String stateName(String code) =>
      states.firstWhere((s) => s.code == code).name;

  @override
  Future<List<Client>> fetchAll() async => List.of(_clients);

  @override
  Future<Client> fetchById(String id) async =>
      _clients.firstWhere((c) => c.id == id);

  @override
  Future<List<IndianState>> fetchStates() async => states;

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
    final id = 'client-${_clients.length + 1}';
    _clients.add(
      Client(
        id: id,
        name: name,
        notes: notes,
        createdAt: DateTime(2026),
        addresses: [
          ClientAddress(
            addressId: '$id-a1',
            clientId: id,
            label: label,
            versionId: '$id-a1-v1',
            version: 1,
            nameOnChallan: nameOnChallan,
            address: address,
            stateCode: stateCode,
            stateName: stateName(stateCode),
            gstin: gstin,
          ),
        ],
      ),
    );
    return id;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    String? notes,
  }) async {
    final index = _clients.indexWhere((c) => c.id == id);
    _clients[index] = _clients[index].copyWith(name: name, notes: notes);
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final index = _clients.indexWhere((c) => c.id == id);
    _clients[index] = _clients[index].copyWith(
      archivedAt: archived ? DateTime(2026) : null,
    );
  }

  @override
  Future<void> delete(String id) async =>
      _clients.removeWhere((c) => c.id == id);

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
    final index = _clients.indexWhere((c) => c.id == clientId);
    final client = _clients[index];
    final saved = ClientAddress(
      addressId: addressId ?? '$clientId-a${client.addresses.length + 1}',
      clientId: clientId,
      label: label,
      versionId: 'v-${DateTime.now().microsecondsSinceEpoch}',
      version: 1,
      nameOnChallan: nameOnChallan,
      address: address,
      stateCode: stateCode,
      stateName: stateName(stateCode),
      gstin: gstin,
    );
    final addresses = [
      for (final a in client.addresses)
        if (a.addressId != saved.addressId) a,
      saved,
    ];
    _clients[index] = client.copyWith(addresses: addresses);
  }

  @override
  Future<void> setAddressArchived(
    String addressId, {
    required bool archived,
  }) async {}

  @override
  Future<void> deleteAddress(String addressId) async {}
}
