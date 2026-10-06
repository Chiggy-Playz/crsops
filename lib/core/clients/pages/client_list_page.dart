import 'package:flutter/material.dart';

import '../../widgets/pane_list_tile.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/two_pane_layout.dart';
import '../../layout/window_size.dart';
import '../../widgets/list_action_row.dart';
import '../../widgets/section_header.dart';
import '../models/client.dart';
import '../providers/client_providers.dart';
import '../routes.dart';

/// Whether [client] matches a lower-cased search [query]: its name, notes,
/// or any address's label, printed name, address, state or GSTIN.
bool clientMatches(Client client, String query) {
  if (query.isEmpty) return true;
  final fields = [
    client.name,
    client.notes ?? '',
    for (final a in client.addresses) ...[
      a.label,
      a.nameOnChallan,
      a.address,
      a.stateName,
      a.gstin ?? '',
    ],
  ];
  return fields.any((field) => field.toLowerCase().contains(query));
}

/// Full page on narrow windows; the left pane of the clients two-pane layout
/// on wide ones, where [selectedId] is highlighted.
class ClientListPage extends ConsumerStatefulWidget {
  const ClientListPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends ConsumerState<ClientListPage> {
  String _query = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);

    final Widget body;
    final clients = clientsAsync.value;
    if (clientsAsync.hasError) {
      body = Center(child: Text('${clientsAsync.error}'));
    } else if (clients != null) {
      body = _buildList(clients);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            tooltip: _showArchived
                ? 'Hide archived clients'
                : 'Show archived clients',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
        bottom: PreferredSize(
          // 8 + 56 search bar + 8, as on the employees list.
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: 'Search clients, addresses, GSTIN',
              leading: const Icon(Icons.search),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: body,
      floatingActionButton: context.isTwoPane
          ? null
          : FloatingActionButton(
              heroTag: 'add-client',
              tooltip: 'Add client',
              onPressed: () => const ClientNewRoute().push(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildList(List<Client> clients) {
    final addRow = context.isTwoPane
        ? ListActionRow(
            icon: Icons.add_business_outlined,
            label: 'New client',
            onTap: () => const ClientNewRoute().push(context),
          )
        : null;

    final matching = clients.where((c) => clientMatches(c, _query)).toList();
    final current = matching.where((c) => !c.isArchived).toList();
    final archived = _showArchived
        ? matching.where((c) => c.isArchived).toList()
        : const <Client>[];

    final String? emptyMessage;
    if (clients.isEmpty) {
      emptyMessage = 'No clients yet';
    } else if (current.isEmpty && archived.isEmpty) {
      emptyMessage = 'No clients match your search';
    } else {
      emptyMessage = null;
    }

    if (emptyMessage != null && addRow == null) {
      return Center(child: Text(emptyMessage));
    }

    return ListView(
      children: [
        ?addRow,
        if (emptyMessage != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(emptyMessage)),
        for (final c in current)
          _ClientTile(client: c, selected: c.id == widget.selectedId),
        if (archived.isNotEmpty) ...[
          const SectionHeader('Archived'),
          for (final c in archived)
            _ClientTile(
              client: c,
              dimmed: true,
              selected: c.id == widget.selectedId,
            ),
        ],
      ],
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({
    required this.client,
    this.dimmed = false,
    this.selected = false,
  });

  final Client client;
  final bool dimmed;
  final bool selected;

  /// "Delhi" for one address, "3 addresses" for several.
  String _subtitle() {
    final active = client.addresses.where((a) => !a.isArchived).toList();
    if (active.length == 1) return active.single.stateName;
    if (active.isEmpty) return 'No addresses';
    return '${active.length} addresses';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PaneListTile(
      title: Text(
        client.name,
        style: dimmed ? TextStyle(color: scheme.onSurfaceVariant) : null,
      ),
      subtitle: Text(_subtitle()),
      selected: selected,
      onTap: () => openInPane(context, ClientDetailRoute(client.id).location),
    );
  }
}
