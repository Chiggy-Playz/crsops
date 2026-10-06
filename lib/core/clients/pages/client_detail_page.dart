import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../layout/two_pane_layout.dart';
import '../../sections/app_sections_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/guarded_save.dart';
import '../../widgets/inset_list_tile.dart';
import '../../widgets/overflow_menu.dart';
import '../../widgets/section_card.dart';
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
  final succeeded = await runGuardedAction(action);
  if (succeeded) ref.read(clientsRevisionProvider.notifier).bump();
  return succeeded;
}

class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.clientId});

  final String clientId;

  Future<void> _setArchived(
    WidgetRef ref,
    Client client, {
    required bool archived,
  }) => _runClientAction(
    ref,
    () => ref
        .read(clientRepositoryProvider)
        .setArchived(client.id, archived: archived),
  );

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Client client,
  ) async {
    final repo = ref.read(clientRepositoryProvider);
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
    final deleted = await _runClientAction(ref, () => repo.delete(client.id));
    if (deleted && context.mounted) {
      context.go(const ClientsRoute().location);
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
            OverflowMenu(
              items: [
                if (client.isArchived)
                  OverflowMenuItem(
                    icon: Icons.unarchive_outlined,
                    label: 'Unarchive',
                    onPressed: () => _setArchived(ref, client, archived: false),
                  )
                else
                  OverflowMenuItem(
                    icon: Icons.archive_outlined,
                    label: 'Archive',
                    onPressed: () => _setArchived(ref, client, archived: true),
                  ),
                OverflowMenuItem(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  destructive: true,
                  onPressed: () => _delete(context, ref, client),
                ),
              ],
            ),
        ],
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (client) {
          final notes = client.notes;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              MaxWidthBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    _Header(client: client),
                    if (notes != null)
                      SectionCard(
                        icon: Icons.notes,
                        title: 'Notes',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(notes),
                        ),
                      ),
                    SectionCard(
                      icon: Icons.place_outlined,
                      title: 'Addresses',
                      action: TextButton.icon(
                        onPressed: () => AddressNewRoute(
                          clientId,
                          $extra: client,
                        ).push(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add address'),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            for (final address in client.addresses)
                              _AddressTile(address: address),
                          ],
                        ),
                      ),
                    ),
                    for (final panel in panels)
                      SectionCard(
                        icon: panel.icon,
                        title: panel.title,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: panel.builder(context, client.id),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
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
    final scheme = theme.colorScheme;
    final activeAddresses = client.addresses.where((a) => !a.isArchived);

    final String summary;
    if (activeAddresses.length == 1) {
      summary = activeAddresses.single.stateName;
    } else {
      summary = '${activeAddresses.length} addresses';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(client.name, style: theme.textTheme.headlineSmall),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (client.isArchived)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      Text(
                        'Archived',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  const _AddressTile({required this.address});

  final ClientAddress address;

  void _edit(BuildContext context) => AddressEditRoute(
    address.clientId,
    address.addressId,
    $extra: address,
  ).push(context);

  Future<void> _setArchived(WidgetRef ref, {required bool archived}) =>
      _runClientAction(
        ref,
        () => ref
            .read(clientRepositoryProvider)
            .setAddressArchived(address.addressId, archived: archived),
      );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(clientRepositoryProvider);
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
    await _runClientAction(ref, () => repo.deleteAddress(address.addressId));
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

    return InsetListTile(
      isThreeLine: true,
      leading: Icon(
        address.isArchived ? Icons.location_off_outlined : Icons.place_outlined,
      ),
      title: Text(
        address.isArchived ? '${address.label} (archived)' : address.label,
        style: address.isArchived ? TextStyle(color: muted) : null,
      ),
      subtitle: Text(lines.join('\n')),
      trailing: OverflowMenu(
        tooltip: 'Address options',
        items: [
          OverflowMenuItem(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onPressed: () => _edit(context),
          ),
          if (address.isArchived)
            OverflowMenuItem(
              icon: Icons.unarchive_outlined,
              label: 'Unarchive',
              onPressed: () => _setArchived(ref, archived: false),
            )
          else
            OverflowMenuItem(
              icon: Icons.archive_outlined,
              label: 'Archive',
              onPressed: () => _setArchived(ref, archived: true),
            ),
          OverflowMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            destructive: true,
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      onTap: () => _edit(context),
    );
  }
}
