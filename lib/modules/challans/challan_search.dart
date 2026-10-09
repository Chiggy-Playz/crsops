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

/// One group of the search results: a client's challans, or, for a client
/// with challans to several of its addresses, one address's.
class ClientChallans {
  const ClientChallans({
    required this.clientName,
    required this.challans,
    this.addressLabel,
  });

  final String clientName;

  /// Set when the client's results are split by address.
  final String? addressLabel;
  final List<Challan> challans;
}

/// Search results grouped by client, clients by name. A client with
/// challans to more than one of its addresses is split into one group per
/// address, by label. Each group keeps the order the challans came in
/// (newest first).
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

  final groups = <ClientChallans>[];
  for (final id in clientIds) {
    final clientChallans = byClient[id]!;
    final byAddress = <String, List<Challan>>{};
    final labels = <String, String>{};
    for (final challan in clientChallans) {
      byAddress.putIfAbsent(challan.addressId, () => []).add(challan);
      labels[challan.addressId] = challan.addressLabel;
    }
    if (byAddress.length == 1) {
      groups.add(
        ClientChallans(clientName: names[id]!, challans: clientChallans),
      );
      continue;
    }
    final addressIds = byAddress.keys.toList()
      ..sort(
        (a, b) => labels[a]!.toLowerCase().compareTo(labels[b]!.toLowerCase()),
      );
    for (final addressId in addressIds) {
      groups.add(
        ClientChallans(
          clientName: names[id]!,
          addressLabel: labels[addressId],
          challans: byAddress[addressId]!,
        ),
      );
    }
  }
  return groups;
}
