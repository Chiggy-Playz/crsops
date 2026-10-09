import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/models/client_address.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/layout/window_size.dart';
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

  /// How many clients and addresses are picked.
  int get count => clientIds.length + addressIds.length;
}

/// The search's "Clients" filter, the way search filter chips work in
/// Google's apps: the chip says what's picked, a click drops the list down
/// under it (a bottom sheet on phones), and every pick applies at once.
/// Click outside or press Esc to close it.
class ClientFilterChip extends StatefulWidget {
  const ClientFilterChip({
    super.key,
    required this.clients,
    required this.value,
    required this.onChanged,
  });

  final List<Client> clients;
  final ClientFilter value;
  final ValueChanged<ClientFilter> onChanged;

  @override
  State<ClientFilterChip> createState() => _ClientFilterChipState();
}

class _ClientFilterChipState extends State<ClientFilterChip> {
  final _menu = MenuController();

  /// Short, like the other chips: "All clients", the one client or site
  /// picked ("VEGA", "OFFSHOOT · Sector 5", cut short on screen), or a count
  /// ("3 clients", "2 clients, 1 site").
  String get _label {
    final filter = widget.value;
    if (filter.isEmpty) return 'All clients';
    if (filter.count == 1) {
      for (final client in widget.clients) {
        if (filter.clientIds.contains(client.id)) return client.name;
        for (final address in client.addresses) {
          if (filter.addressIds.contains(address.addressId)) {
            return '${client.name} · ${address.label}';
          }
        }
      }
    }
    final clients = _plural(filter.clientIds.length, 'client', 'clients');
    final sites = _plural(filter.addressIds.length, 'site', 'sites');
    if (filter.addressIds.isEmpty) return clients;
    if (filter.clientIds.isEmpty) return sites;
    return '$clients, $sites';
  }

  /// Everything picked, one per line, for the chip's tooltip.
  String get _fullNames {
    final filter = widget.value;
    final names = <String>[];
    for (final client in widget.clients) {
      if (filter.clientIds.contains(client.id)) names.add(client.name);
      for (final address in client.addresses) {
        if (filter.addressIds.contains(address.addressId)) {
          names.add('${client.name} · ${address.label}');
        }
      }
    }
    return names.join('\n');
  }

  static String _plural(int count, String one, String many) {
    if (count == 1) return '1 $one';
    return '$count $many';
  }

  Future<void> _open() async {
    if (context.windowSize != WindowSize.compact) {
      if (_menu.isOpen) {
        _menu.close();
      } else {
        _menu.open();
      }
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.75,
        child: _ClientFilterPanel(
          clients: widget.clients,
          initialValue: widget.value,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = math.min(400.0, MediaQuery.sizeOf(context).height * 0.6);

    // Flutter's menu does the placing under the chip, the closing on a click
    // outside or Esc, and keeps it on screen.
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: 360,
          height: height,
          child: _ClientFilterPanel(
            clients: widget.clients,
            initialValue: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      ],
      builder: (context, controller, _) => InputChip(
        avatar: const Icon(Icons.business_outlined, size: 18),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(_label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        tooltip: widget.value.isEmpty ? null : _fullNames,
        selected: !widget.value.isEmpty,
        showCheckmark: false,
        onPressed: _open,
        onDeleted: widget.value.isEmpty
            ? null
            : () => widget.onChanged(const ClientFilter()),
      ),
    );
  }
}

/// The list itself: search, then the clients, picked ones first. A client
/// with several addresses can be picked whole, or unfolded (▸) to pick some
/// of its addresses.
class _ClientFilterPanel extends StatefulWidget {
  const _ClientFilterPanel({
    required this.clients,
    required this.initialValue,
    required this.onChanged,
  });

  final List<Client> clients;
  final ClientFilter initialValue;
  final ValueChanged<ClientFilter> onChanged;

  @override
  State<_ClientFilterPanel> createState() => _ClientFilterPanelState();
}

class _ClientFilterPanelState extends State<_ClientFilterPanel> {
  late final Set<String> _clientIds = Set.of(widget.initialValue.clientIds);
  late final Set<String> _addressIds = Set.of(widget.initialValue.addressIds);
  final Set<String> _unfolded = {};
  String _query = '';

  /// Clients picked when the list opened, shown first. Fixed while it's
  /// open, so rows don't jump about under the pointer.
  late final Set<String> _pickedAtOpen = {
    for (final client in widget.clients)
      if (_clientValue(client) != false) client.id,
  };

  void _changed() => widget.onChanged(
    ClientFilter(
      clientIds: Set.of(_clientIds),
      addressIds: Set.of(_addressIds),
    ),
  );

  /// Picked whole (true), some addresses (null), or not at all.
  bool? _clientValue(Client client) {
    if (_clientIds.contains(client.id)) return true;
    final someAddresses = client.addresses.any(
      (a) => _addressIds.contains(a.addressId),
    );
    if (someAddresses) return null;
    return false;
  }

  /// All of it, or (when it was all) none of it.
  void _toggleClient(Client client) {
    setState(() {
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
    _changed();
  }

  /// One address. Unpicking one of a wholly picked client keeps the rest;
  /// picking the last missing one makes the client whole again.
  void _toggleAddress(Client client, ClientAddress address) {
    setState(() {
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
      final allPicked = client.addresses.every(
        (a) => _addressIds.contains(a.addressId),
      );
      if (allPicked) {
        for (final a in client.addresses) {
          _addressIds.remove(a.addressId);
        }
        _clientIds.add(client.id);
      }
    });
    _changed();
  }

  void _clear() {
    setState(() {
      _clientIds.clear();
      _addressIds.clear();
    });
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final matching = widget.clients
        .where((c) => clientMatches(c, _query))
        .toList();
    final picked = matching.where((c) => _pickedAtOpen.contains(c.id));
    final active = matching.where(
      (c) => !c.isArchived && !_pickedAtOpen.contains(c.id),
    );
    final archived = matching.where(
      (c) => c.isArchived && !_pickedAtOpen.contains(c.id),
    );
    final anyPicked = _clientIds.isNotEmpty || _addressIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search clients',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
              ),
              if (anyPicked)
                TextButton(onPressed: _clear, child: const Text('Clear')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            // Its own scrolling: inside the menu, which has a scrollbar of
            // its own on the shared controller.
            primary: false,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              if (picked.isNotEmpty) ...[
                const SectionHeader('Picked', topPadding: 8),
                for (final c in picked) ..._rows(c),
              ],
              if (active.isNotEmpty) ...[
                if (picked.isNotEmpty) const SectionHeader('All clients'),
                for (final c in active) ..._rows(c),
              ],
              if (archived.isNotEmpty) ...[
                const SectionHeader('Archived'),
                for (final c in archived) ..._rows(c),
              ],
              if (matching.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No clients match'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The client's row and, unfolded, one indented row per address.
  List<Widget> _rows(Client client) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasSites = client.addresses.length > 1;
    // Unfolded on request, or while searching (the match may be an address).
    final unfolded =
        hasSites && (_unfolded.contains(client.id) || _query.isNotEmpty);

    final String? subtitle;
    if (hasSites) {
      subtitle = '${client.addresses.length} addresses';
    } else if (client.addresses.isEmpty) {
      subtitle = null;
    } else {
      subtitle = client.addresses.single.stateName;
    }

    Widget? fold;
    if (hasSites) {
      fold = IconButton(
        icon: Icon(unfolded ? Icons.expand_less : Icons.expand_more),
        tooltip: unfolded ? 'Hide addresses' : 'Show addresses',
        onPressed: () => setState(() {
          if (!_unfolded.remove(client.id)) _unfolded.add(client.id);
        }),
      );
    }

    return [
      _PickRow(
        leading: InitialsAvatar(name: client.name, dimmed: client.isArchived),
        title: Text(
          client.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: client.isArchived ? TextStyle(color: muted) : null,
        ),
        subtitle: subtitle,
        trailing: fold,
        value: _clientValue(client),
        onChanged: () => _toggleClient(client),
      ),
      if (unfolded)
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
    this.trailing,
  });

  /// Shown while not picked: initials, or an icon.
  final Widget leading;
  final Widget title;
  final String? subtitle;
  final Widget? trailing;

  /// Null when partly picked.
  final bool? value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    final picked = value;

    final Widget marker;
    final String state;
    if (picked == true) {
      marker = CircleAvatar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.check),
      );
      state = 'selected';
    } else if (picked == null) {
      marker = CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        child: const Icon(Icons.remove),
      );
      state = 'partly selected';
    } else {
      marker = SizedBox(width: 40, child: Center(child: leading));
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
        trailing: trailing,
        selected: picked == true,
        onTap: onChanged,
      ),
    );
  }
}
