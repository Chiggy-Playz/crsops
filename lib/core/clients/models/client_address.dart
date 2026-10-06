import 'package:dart_mappable/dart_mappable.dart';

part 'client_address.mapper.dart';

/// One site of a client with its current details, as read from the
/// `core.current_client_addresses` view (the address joined to its newest
/// version). Challans point at [versionId], not at the address.
@MappableClass()
class ClientAddress with ClientAddressMappable {
  const ClientAddress({
    required this.addressId,
    required this.clientId,
    required this.label,
    this.archivedAt,
    required this.versionId,
    required this.version,
    required this.nameOnChallan,
    required this.address,
    required this.stateCode,
    required this.stateName,
    this.gstin,
  });

  @MappableField(key: 'address_id')
  final String addressId;
  @MappableField(key: 'client_id')
  final String clientId;

  /// Internal name for the site ("Sector 4"); never printed.
  @MappableField(key: 'label')
  final String label;
  @MappableField(key: 'archived_at')
  final DateTime? archivedAt;
  @MappableField(key: 'version_id')
  final String versionId;
  @MappableField(key: 'version')
  final int version;
  @MappableField(key: 'name_on_challan')
  final String nameOnChallan;
  @MappableField(key: 'address')
  final String address;
  @MappableField(key: 'state_code')
  final String stateCode;
  @MappableField(key: 'state_name')
  final String stateName;
  @MappableField(key: 'gstin')
  final String? gstin;

  bool get isArchived => archivedAt != null;
}
