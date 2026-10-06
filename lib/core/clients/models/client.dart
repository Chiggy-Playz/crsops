import 'package:dart_mappable/dart_mappable.dart';

import 'client_address.dart';

part 'client.mapper.dart';

/// A company challans are made out to. Its sites are [addresses].
@MappableClass()
class Client with ClientMappable {
  const Client({
    required this.id,
    required this.name,
    this.notes,
    this.archivedAt,
    required this.createdAt,
    this.addresses = const [],
  });

  @MappableField(key: 'id')
  final String id;
  @MappableField(key: 'name')
  final String name;

  /// Internal notes, e.g. who referred them. Never printed.
  @MappableField(key: 'notes')
  final String? notes;
  @MappableField(key: 'archived_at')
  final DateTime? archivedAt;
  @MappableField(key: 'created_at')
  final DateTime createdAt;

  /// Not a column of `clients`: the repository fills it in from
  /// `current_client_addresses`, sorted by label.
  @MappableField(key: 'addresses')
  final List<ClientAddress> addresses;

  bool get isArchived => archivedAt != null;
}
