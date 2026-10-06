import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/list_action_row.dart';
import '../../routes.dart';
import '../../providers/challan_providers.dart';
import 'challan_tile.dart';

/// A client's challans on the client's page (added through the challans
/// section's client panel). Shows the latest few, with a button for the rest.
class ClientChallansPanel extends ConsumerStatefulWidget {
  const ClientChallansPanel({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<ClientChallansPanel> createState() =>
      _ClientChallansPanelState();
}

class _ClientChallansPanelState extends ConsumerState<ClientChallansPanel> {
  static const _shownAtFirst = 10;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final challansAsync = ref.watch(clientChallansProvider(widget.clientId));

    final newRow = ListActionRow(
      icon: Icons.add,
      label: 'New outward challan',
      // The form belongs to the Challans section, so this switches to it.
      onTap: () => ChallanNewRoute(clientId: widget.clientId).go(context),
    );

    return challansAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Padding(padding: const EdgeInsets.all(16), child: Text('$error')),
      data: (challans) {
        final shown = _showAll
            ? challans
            : challans.take(_shownAtFirst).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            newRow,
            if (challans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No challans yet'),
              ),
            for (final challan in shown)
              ChallanTile(
                challan: challan,
                showDirection: true,
                onTap: () => ChallanDetailRoute(challan.id).go(context),
              ),
            if (shown.length < challans.length)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = true),
                    child: Text('Show all ${challans.length}'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
