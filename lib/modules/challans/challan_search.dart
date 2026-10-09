import 'package:dart_mappable/dart_mappable.dart';

import 'models/challan.dart';
import 'models/challan_direction.dart';

part 'challan_search.mapper.dart';

/// What to search for. Empty fields are ignored. Mappable for its equality,
/// so the same filters give the same cached results.
@MappableClass()
class ChallanSearchFilters with ChallanSearchFiltersMappable {
  const ChallanSearchFilters({
    this.text = '',
    this.clientIds = const [],
    this.addressIds = const [],
    this.from,
    this.to,
    this.direction,
  });

  /// A challan number, or part of a name, item, serial, vehicle, bill number
  /// or note.
  final String text;

  /// Whole clients: every address they have.
  final List<String> clientIds;

  /// Single addresses, for a client with several sites. A challan matches if
  /// its client is in [clientIds] or its address is in [addressIds]; both
  /// empty means every client.
  final List<String> addressIds;
  final DateTime? from;
  final DateTime? to;

  /// Null for both directions.
  final ChallanDirection? direction;

  bool get isEmpty =>
      text.trim().isEmpty &&
      clientIds.isEmpty &&
      addressIds.isEmpty &&
      from == null &&
      to == null;
}

/// One client's challans in the search results.
class ClientChallans {
  const ClientChallans({
    required this.clientId,
    required this.clientName,
    required this.challans,
    required this.spansAddresses,
  });

  final String clientId;
  final String clientName;
  final List<Challan> challans;

  /// Whether the challans went to more than one of the client's addresses,
  /// so each row says which.
  final bool spansAddresses;
}

/// Search results grouped by client, clients by name; each client's challans
/// keep the order they came in (newest first).
List<ClientChallans> groupByClient(List<Challan> challans) {
  final byClient = <String, List<Challan>>{};
  final names = <String, String>{};
  for (final challan in challans) {
    byClient.putIfAbsent(challan.clientId, () => []).add(challan);
    names[challan.clientId] = challan.clientName;
  }
  final clientIds = byClient.keys.toList()
    ..sort(
      (a, b) => names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase()),
    );
  return [
    for (final id in clientIds)
      ClientChallans(
        clientId: id,
        clientName: names[id]!,
        challans: byClient[id]!,
        spansAddresses:
            byClient[id]!.map((c) => c.addressId).toSet().length > 1,
      ),
  ];
}
