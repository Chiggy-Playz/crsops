import 'package:flutter/material.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/models/client_address.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/widgets/form_dialog.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../../core/widgets/inset_list_tile.dart';
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
            _PickRow(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('All clients'),
              value: count == 0,
              onChanged: () => setState(() {
                _clientIds.clear();
                _addressIds.clear();
              }),
            ),
            const Divider(),
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
  /// row per address. Picked rows show a check and the list's highlight
  /// instead of checkboxes.
  List<Widget> _rows(Client client, {required bool archived}) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasSites = client.addresses.length > 1;

    final String? clientSubtitle;
    if (hasSites) {
      clientSubtitle = '${client.addresses.length} addresses';
    } else if (client.addresses.isEmpty) {
      clientSubtitle = null;
    } else {
      clientSubtitle = client.addresses.single.stateName;
    }

    return [
      _PickRow(
        leading: InitialsAvatar(name: client.name, dimmed: archived),
        title: Text(
          client.name,
          style: archived ? TextStyle(color: muted) : null,
        ),
        subtitle: clientSubtitle,
        value: _clientValue(client),
        onChanged: () => _toggleClient(client),
      ),
      if (hasSites)
        for (final address in client.addresses)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: _PickRow(
              leading: const Icon(Icons.place_outlined),
              title: Text(
                address.isArchived
                    ? '${address.label} (archived)'
                    : address.label,
                style: address.isArchived ? TextStyle(color: muted) : null,
              ),
              subtitle: _whereIs(address),
              value:
                  _clientIds.contains(client.id) ||
                  _addressIds.contains(address.addressId),
              onChanged: () => _toggleAddress(client, address),
            ),
          ),
    ];
  }

  /// "Haryana · Plot 96, Udyog Vihar": enough to tell sites apart.
  static String _whereIs(ClientAddress address) {
    final firstLine = address.address.split('\n').first.trim();
    if (firstLine.isEmpty) return address.stateName;
    return '${address.stateName} · $firstLine';
  }
}

/// A row that can be picked: picked, its icon becomes a check in a filled
/// circle and the row takes the list's highlight; partly picked (some of a
/// client's addresses), a dash.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  /// Shown while not picked: initials, or an icon.
  final Widget leading;
  final Widget title;
  final String? subtitle;

  /// Null when partly picked.
  final bool? value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    final picked = value;

    final Widget marker;
    if (picked == true) {
      marker = CircleAvatar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.check),
      );
    } else if (picked == null) {
      marker = CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: const Icon(Icons.remove),
      );
    } else {
      marker = SizedBox(width: 40, child: Center(child: leading));
    }

    final String state;
    if (picked == true) {
      state = 'selected';
    } else if (picked == null) {
      state = 'partly selected';
    } else {
      state = 'not selected';
    }

    return Semantics(
      value: state,
      child: InsetListTile(
        leading: marker,
        title: title,
        subtitle: subtitle == null
            ? null
            : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: picked == true,
        onTap: onChanged,
      ),
    );
  }
}
