import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../errors/app_exception.dart';
import '../../layout/two_pane_layout.dart';
import '../../sections/app_sections_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/list_action_row.dart';
import '../../widgets/section_header.dart';
import '../models/client.dart';
import '../models/client_address.dart';
import '../providers/client_providers.dart';
import '../routes.dart';

/// Runs a client/address write, shows its error if it fails, and refreshes
/// everything that shows clients if it succeeds. Returns whether it worked.
Future<bool> _runClientAction(
  WidgetRef ref,
  Future<void> Function() action,
) async {
  try {
    await action();
    ref.read(clientsRevisionProvider.notifier).bump();
    return true;
  } on AppException catch (e) {
    showErrorSnackBar(e);
    return false;
  }
}

enum _ClientMenuAction { archive, unarchive, delete }

enum _AddressMenuAction { edit, archive, unarchive, delete }

class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    Client client,
    _ClientMenuAction action,
  ) async {
    final repo = ref.read(clientRepositoryProvider);
    switch (action) {
      case _ClientMenuAction.archive:
        await _runClientAction(
          ref,
          () => repo.setArchived(client.id, archived: true),
        );
      case _ClientMenuAction.unarchive:
        await _runClientAction(
          ref,
          () => repo.setArchived(client.id, archived: false),
        );
      case _ClientMenuAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete client?',
          message:
              '${client.name} and all its addresses will be removed. '
              "This only works if it isn't on any challan.",
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (!confirmed) return;
        final deleted = await _runClientAction(
          ref,
          () => repo.delete(client.id),
        );
        if (deleted && context.mounted) {
          context.go(const ClientsRoute().location);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));
    final session = ref.watch(sessionProvider).value;
    final sections = ref.watch(appSectionsProvider);
    final client = clientAsync.value;
    final leading = paneLeading(
      context,
      parentLocation: const ClientsRoute().location,
    );

    // Blocks other sections add here, e.g. this client's challans.
    final panels = [
      if (session != null)
        for (final section in sections)
          for (final panel in section.clientPanels)
            if (panel.canSee(session)) panel,
    ];

    return Scaffold(
      // No title: the header below shows the name, once.
      appBar: AppBar(
        leading: leading.leading,
        automaticallyImplyLeading: leading.implyLeading,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit client',
            onPressed: client == null
                ? null
                : () => ClientEditRoute(clientId, $extra: client).push(context),
          ),
          if (client != null)
            PopupMenuButton<_ClientMenuAction>(
              tooltip: 'More',
              onSelected: (action) => _onMenu(context, ref, client, action),
              itemBuilder: (context) => [
                if (client.isArchived)
                  const PopupMenuItem(
                    value: _ClientMenuAction.unarchive,
                    child: Text('Unarchive'),
                  )
                else
                  const PopupMenuItem(
                    value: _ClientMenuAction.archive,
                    child: Text('Archive'),
                  ),
                const PopupMenuItem(
                  value: _ClientMenuAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (client) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(client: client),
            if (client.notes != null)
              ListTile(
                leading: const Icon(Icons.notes),
                title: Text(client.notes!),
                subtitle: const Text('Notes'),
              ),
            const SectionHeader('Addresses'),
            for (final address in client.addresses)
              _AddressTile(address: address),
            ListActionRow(
              icon: Icons.add_location_alt_outlined,
              label: 'Add address',
              onTap: () =>
                  AddressNewRoute(clientId, $extra: client).push(context),
            ),
            for (final panel in panels) ...[
              SectionHeader(panel.title),
              panel.builder(context, client.id),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name, style: theme.textTheme.headlineSmall),
          if (client.isArchived) ...[
            const SizedBox(height: 4),
            Text(
              'Archived',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  const _AddressTile({required this.address});

  final ClientAddress address;

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _AddressMenuAction action,
  ) async {
    final repo = ref.read(clientRepositoryProvider);
    switch (action) {
      case _AddressMenuAction.edit:
        AddressEditRoute(
          address.clientId,
          address.addressId,
          $extra: address,
        ).push(context);
      case _AddressMenuAction.archive:
        await _runClientAction(
          ref,
          () => repo.setAddressArchived(address.addressId, archived: true),
        );
      case _AddressMenuAction.unarchive:
        await _runClientAction(
          ref,
          () => repo.setAddressArchived(address.addressId, archived: false),
        );
      case _AddressMenuAction.delete:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete address?',
          message:
              '"${address.label}" will be removed. '
              "This only works if it isn't on any challan.",
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        if (!confirmed) return;
        await _runClientAction(
          ref,
          () => repo.deleteAddress(address.addressId),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final lines = [
      address.nameOnChallan,
      address.address,
      address.stateName,
      'GSTIN: ${address.gstin ?? 'none'}',
    ];

    return ListTile(
      isThreeLine: true,
      leading: Icon(
        address.isArchived ? Icons.location_off_outlined : Icons.place_outlined,
      ),
      title: Text(
        address.isArchived ? '${address.label} (archived)' : address.label,
        style: address.isArchived ? TextStyle(color: muted) : null,
      ),
      subtitle: Text(lines.join('\n')),
      trailing: PopupMenuButton<_AddressMenuAction>(
        tooltip: 'Address options',
        onSelected: (action) => _onMenu(context, ref, action),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _AddressMenuAction.edit,
            child: Text('Edit'),
          ),
          if (address.isArchived)
            const PopupMenuItem(
              value: _AddressMenuAction.unarchive,
              child: Text('Unarchive'),
            )
          else
            const PopupMenuItem(
              value: _AddressMenuAction.archive,
              child: Text('Archive'),
            ),
          const PopupMenuItem(
            value: _AddressMenuAction.delete,
            child: Text('Delete'),
          ),
        ],
      ),
      onTap: () => AddressEditRoute(
        address.clientId,
        address.addressId,
        $extra: address,
      ).push(context),
    );
  }
}
