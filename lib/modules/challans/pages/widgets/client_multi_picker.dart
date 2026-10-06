import 'package:flutter/material.dart';

import '../../../../core/clients/models/client.dart';
import '../../../../core/clients/pages/client_list_page.dart';
import '../../../../core/widgets/form_dialog.dart';
import '../../../../core/widgets/section_header.dart';

/// Multi-select client picker for the search filter, built like the Reports
/// employee picker: search, active clients, then a dimmed Archived group
/// (old challans belong to them too). Full-screen on phones, a dialog on
/// wide windows.
///
/// Resolves to the chosen ids (empty = every client), or null if dismissed.
Future<Set<String>?> showClientMultiPicker(
  BuildContext context, {
  required List<Client> clients,
  required Set<String> initialSelection,
}) => showFormDialog<Set<String>>(
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
  final Set<String> initialSelection;

  @override
  State<_ClientMultiPicker> createState() => _ClientMultiPickerState();
}

class _ClientMultiPickerState extends State<_ClientMultiPicker> {
  final _formKey = GlobalKey<FormState>();
  late final Set<String> _selection = Set.of(widget.initialSelection);
  String _query = '';

  void _toggle(String id, bool selected) => setState(() {
    if (selected) {
      _selection.add(id);
    } else {
      _selection.remove(id);
    }
  });

  @override
  Widget build(BuildContext context) {
    final matching = widget.clients
        .where((c) => clientMatches(c, _query))
        .toList();
    final active = matching.where((c) => !c.isArchived).toList();
    final archived = matching.where((c) => c.isArchived).toList();

    final String description;
    if (_selection.isEmpty) {
      description = 'Searching every client';
    } else {
      description = '${_selection.length} selected';
    }

    return FormDialog(
      title: 'Filter by client',
      description: description,
      formKey: _formKey,
      saving: false,
      saveLabel: 'Apply',
      onSave: () => Navigator.of(context).pop(_selection),
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
              value: _selection.isEmpty,
              onChanged: (_) => setState(_selection.clear),
            ),
            const Divider(height: 1),
            for (final c in active) _row(c, archived: false),
            if (archived.isNotEmpty) ...[
              const SectionHeader('Archived', topPadding: 16),
              for (final c in archived) _row(c, archived: true),
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

  Widget _row(Client client, {required bool archived}) {
    final dimmedText = archived
        ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
        : null;
    return CheckboxListTile(
      title: Text(client.name, style: dimmedText),
      value: _selection.contains(client.id),
      onChanged: (checked) => _toggle(client.id, checked ?? false),
    );
  }
}
