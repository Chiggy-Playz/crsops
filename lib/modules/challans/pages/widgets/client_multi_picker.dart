import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/clients/providers/client_providers.dart';
import '../../../../core/layout/window_size.dart';
import '../../../../core/widgets/adaptive_sheet.dart';

/// Lets the user tick any number of clients (archived ones included, since
/// old challans belong to them). Resolves to the ticked clients, or null if
/// dismissed.
Future<List<Client>?> showClientMultiPicker(
  BuildContext context, {
  required List<Client> selected,
}) => showAdaptiveSheet<List<Client>>(
  context: context,
  builder: (_) => _ClientMultiPicker(selected: selected),
);

class _ClientMultiPicker extends ConsumerStatefulWidget {
  const _ClientMultiPicker({required this.selected});

  final List<Client> selected;

  @override
  ConsumerState<_ClientMultiPicker> createState() => _ClientMultiPickerState();
}

class _ClientMultiPickerState extends ConsumerState<_ClientMultiPicker> {
  late final Set<String> _ticked = {for (final c in widget.selected) c.id};
  String _query = '';

  void _done(List<Client> clients) {
    Navigator.of(context).pop([
      for (final c in clients)
        if (_ticked.contains(c.id)) c,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final clients = clientsAsync.value ?? const <Client>[];
    final matching = clients.where((c) => clientMatches(c, _query)).toList();

    final Widget list;
    if (clientsAsync.hasError) {
      list = Center(child: Text('${clientsAsync.error}'));
    } else if (clientsAsync.value == null) {
      list = const Center(child: CircularProgressIndicator());
    } else {
      list = ListView.builder(
        itemCount: matching.length,
        itemBuilder: (context, index) {
          final client = matching[index];
          return CheckboxListTile(
            value: _ticked.contains(client.id),
            title: Text(client.name),
            subtitle: client.isArchived ? const Text('Archived') : null,
            onChanged: (ticked) => setState(() {
              if (ticked ?? false) {
                _ticked.add(client.id);
              } else {
                _ticked.remove(client.id);
              }
            }),
          );
        },
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, context.isTwoPane ? 24 : 0, 16, 8),
            child: SearchBar(
              autoFocus: context.isTwoPane,
              hintText: 'Search clients',
              leading: const Icon(Icons.search),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(child: list),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => setState(_ticked.clear),
                  child: const Text('Clear'),
                ),
                FilledButton(
                  onPressed: () => _done(clients),
                  child: Text('Done (${_ticked.length})'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
