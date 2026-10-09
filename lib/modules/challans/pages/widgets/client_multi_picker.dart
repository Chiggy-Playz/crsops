import 'package:flutter/material.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/models/client_address.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/widgets/form_dialog.dart';
import '../../../../core/widgets/section_header.dart';

/// What the search's client filter picked: whole clients (every address
/// they have) and single addresses of clients with several sites. Both
/// empty means every client.
class ClientFilter {
  const ClientFilter({this.clientIds = const {}, this.addressIds = const {}});

  final Set<String> clientIds;
  final Set<String> addressIds;

  bool get isEmpty => clientIds.isEmpty && addressIds.isEmpty;

  /// How many clients and addresses are ticked.
  int get count => clientIds.length + addressIds.length;
}

/// Multi-select client picker for the search filter, built like the Reports
/// employee picker: search, active clients, then a dimmed Archived group
/// (old challans belong to them too). A client with several addresses can
/// be ticked whole or just some of its addresses. Full-screen on phones, a
/// dialog on wide windows.
///
/// Resolves to the choice, or null if dismissed.
Future<ClientFilter?> showClientMultiPicker(
  BuildContext context, {
  required List<Client> clients,
  required ClientFilter initialSelection,
}) => showFormDialog<ClientFilter>(
  context: context,
  builder: (_) =>
      _ClientMultiPicker(clients: clients, initialSelection: initialSelection),
);

class _ClientMultiPicker extends StatefulWidget {
  const _ClientMultiPicker({
    required this.clients,
    required this.initialSelection,
  });

  final List<Client> clients;
  final ClientFilter initialSelection;

  @override
  State<_ClientMultiPicker> createState() => _ClientMultiPickerState();
}

class _ClientMultiPickerState extends State<_ClientMultiPicker> {
  final _formKey = GlobalKey<FormState>();
  late final Set<String> _clientIds = Set.of(widget.initialSelection.clientIds);
  late final Set<String> _addressIds = Set.of(
    widget.initialSelection.addressIds,
  );
  String _query = '';

  /// A client's box: ticked whole (true), some addresses (null), or none.
  bool? _clientValue(Client client) {
    if (_clientIds.contains(client.id)) return true;
    final someAddresses = client.addresses.any(
      (a) => _addressIds.contains(a.addressId),
    );
    if (someAddresses) return null;
    return false;
  }

  /// All of it, or (when it was all) none of it.
  void _toggleClient(Client client) => setState(() {
    final wasWhole = _clientIds.contains(client.id);
    for (final address in client.addresses) {
      _addressIds.remove(address.addressId);
    }
    if (wasWhole) {
      _clientIds.remove(client.id);
    } else {
      _clientIds.add(client.id);
    }
  });

  /// One address. Unticking one of a wholly ticked client keeps the rest;
  /// ticking the last missing one makes the client whole again.
  void _toggleAddress(Client client, ClientAddress address) => setState(() {
    if (_clientIds.remove(client.id)) {
      for (final other in client.addresses) {
        if (other.addressId != address.addressId) {
          _addressIds.add(other.addressId);
        }
      }
      return;
    }
    if (!_addressIds.remove(address.addressId)) {
      _addressIds.add(address.addressId);
    }
    final allTicked = client.addresses.every(
      (a) => _addressIds.contains(a.addressId),
    );
    if (allTicked) {
      for (final a in client.addresses) {
        _addressIds.remove(a.addressId);
      }
      _clientIds.add(client.id);
    }
  });

  @override
  Widget build(BuildContext context) {
    final matching = widget.clients
        .where((c) => clientMatches(c, _query))
        .toList();
    final active = matching.where((c) => !c.isArchived).toList();
    final archived = matching.where((c) => c.isArchived).toList();

    final count = _clientIds.length + _addressIds.length;
    final String description;
    if (count == 0) {
      description = 'Searching every client';
    } else {
      description = '$count selected';
    }

    return FormDialog(
      title: 'Filter by client',
      description: description,
      formKey: _formKey,
      saving: false,
      saveLabel: 'Apply',
      onSave: () => Navigator.of(context)
          .pop(ClientFilter(clientIds: _clientIds, addressIds: _addressIds)),
      children: [
        TextField(
          autofocus: !FormDialog.isCompact(context),
          decoration: const InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
        ),
        // One child, so the rows aren't spaced like separate form fields.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              title: const Text('All clients'),
              value: count == 0,
              onChanged: (_) => setState(() {
                _clientIds.clear();
                _addressIds.clear();
              }),
            ),
            const Divider(height: 1),
            for (final c in active) ..._rows(c, archived: false),
            if (archived.isNotEmpty) ...[
              const SectionHeader('Archived', topPadding: 16),
              for (final c in archived) ..._rows(c, archived: true),
            ],
            if (matching.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No clients match your search'),
              ),
          ],
        ),
      ],
    );
  }

  /// The client's row, and for a client with several addresses one indented
  /// row per address.
  List<Widget> _rows(Client client, {required bool archived}) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dimmedText = archived ? TextStyle(color: muted) : null;
    final hasSites = client.addresses.length > 1;

    return [
      CheckboxListTile(
        title: Text(client.name, style: dimmedText),
        subtitle: hasSites
            ? Text('${client.addresses.length} addresses')
            : null,
        tristate: hasSites,
        value: _clientValue(client),
        onChanged: (_) => _toggleClient(client),
      ),
      if (hasSites)
        for (final address in client.addresses)
          CheckboxListTile(
            contentPadding: const EdgeInsets.only(left: 40, right: 16),
            title: Text(
              address.isArchived
                  ? '${address.label} (archived)'
                  : address.label,
              style: address.isArchived ? TextStyle(color: muted) : dimmedText,
            ),
            subtitle: Text(address.stateName),
            value:
                _clientIds.contains(client.id) ||
                _addressIds.contains(address.addressId),
            onChanged: (_) => _toggleAddress(client, address),
          ),
    ];
  }
}
