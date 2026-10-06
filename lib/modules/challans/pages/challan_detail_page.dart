import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clients/providers/client_providers.dart';
import '../../../core/clients/routes.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/section_header.dart';
import '../financial_year.dart';
import '../models/challan.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/cancel_challan_dialog.dart';
import 'widgets/challan_action.dart';
import 'widgets/challan_history_section.dart';
import 'widgets/follow_ups_section.dart';

class ChallanDetailPage extends ConsumerWidget {
  const ChallanDetailPage({super.key, required this.challanId});

  final String challanId;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Challan challan,
  ) async {
    final choice = await showCancelChallanDialog(context, challan);
    if (choice == null) return;
    final cancelled = await runChallanAction(
      ref,
      () => ref
          .read(challanRepositoryProvider)
          .cancel(
            challan.id,
            reason: choice.reason,
            createReturn: choice.createReturn,
          ),
    );
    // A return challan locks nothing new, but the client page lists it.
    if (cancelled) ref.read(clientsRevisionProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challanAsync = ref.watch(challanProvider(challanId));
    final challan = challanAsync.value;
    final leading = paneLeading(
      context,
      parentLocation: const ChallansRoute().location,
    );

    return Scaffold(
      appBar: AppBar(
        leading: leading.leading,
        automaticallyImplyLeading: leading.implyLeading,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Print or share PDF',
            onPressed: challan == null
                ? null
                : () => ChallanPdfRoute(challan.id).push(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit challan',
            onPressed: challan == null || challan.isCancelled
                ? null
                : () => ChallanEditRoute(
                    challan.id,
                    $extra: challan,
                  ).push(context),
          ),
          if (challan != null)
            OverflowMenu(
              items: [
                OverflowMenuItem(
                  icon: Icons.business_outlined,
                  label: 'Open client',
                  onPressed: () =>
                      ClientDetailRoute(challan.clientId).go(context),
                ),
                if (!challan.isCancelled)
                  OverflowMenuItem(
                    icon: Icons.block,
                    label: 'Cancel challan',
                    destructive: true,
                    onPressed: () => _cancel(context, ref, challan),
                  ),
              ],
            ),
        ],
      ),
      body: challanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (challan) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Header(challan: challan),
            _LinkedChallan(challan: challan),
            const SectionHeader('Client'),
            _ClientDetails(challan: challan),
            SectionHeader('Items · total ${challan.totalQuantity}'),
            for (final (index, item) in challan.items.indexed)
              ListTile(
                leading: SizedBox(
                  width: 24,
                  child: Text('${index + 1}', textAlign: TextAlign.center),
                ),
                title: Text(item.description),
                subtitle: _itemSubtitle(
                  item.additionalDescription,
                  item.serial,
                ),
                trailing: Text(item.quantityText),
              ),
            const SectionHeader('Details'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(challan.handledByName),
              subtitle: Text(challan.direction.handledByLabel),
            ),
            if (challan.vehicleNumber != null)
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(challan.vehicleNumber!),
                subtitle: const Text('Vehicle'),
              ),
            if (challan.declaredValue != null)
              ListTile(
                leading: const Icon(Icons.currency_rupee),
                title: Text(formatRupees(challan.declaredValue!)),
                subtitle: const Text('Value of goods'),
              ),
            if (challan.notes != null)
              ListTile(
                leading: const Icon(Icons.notes),
                title: Text(challan.notes!),
                subtitle: const Text('Notes'),
              ),
            if (challan.isOutward) ...[
              const SectionHeader('After delivery'),
              FollowUpsSection(challan: challan),
            ],
            const SectionHeader('History'),
            ChallanHistorySection(challan: challan),
          ],
        ),
      ),
    );
  }

  static Widget? _itemSubtitle(String? additional, String? serial) {
    final lines = [?additional, if (serial != null) 'Serial: $serial'];
    if (lines.isEmpty) return null;
    return Text(lines.join('\n'));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            '${challan.direction.label} challan ${challan.numberLabel}',
            style: theme.textTheme.headlineSmall,
          ),
          Text(
            formatDisplayDate(challan.challanDate),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (challan.isCancelled) ...[
            const SizedBox(height: 4),
            Text(
              'Cancelled',
              style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
            ),
            if (challan.cancelReason != null) Text(challan.cancelReason!),
          ],
        ],
      ),
    );
  }
}

/// The challan linked to this one by a cancellation, if any.
class _LinkedChallan extends StatelessWidget {
  const _LinkedChallan({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final returnedById = challan.returnedByChallanId;
    final reversesId = challan.reversesChallanId;

    if (returnedById != null) {
      final label = challanNumberLabel(
        challan.returnedByNumber!,
        challan.returnedByFinancialYear!,
      );
      return ListTile(
        leading: const Icon(Icons.call_received),
        title: Text('Brought back on inward challan $label'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            openInPane(context, ChallanDetailRoute(returnedById).location),
      );
    }
    if (reversesId != null) {
      final label = challanNumberLabel(
        challan.reversesNumber!,
        challan.reversesFinancialYear!,
      );
      return ListTile(
        leading: const Icon(Icons.call_made),
        title: Text('Brings back cancelled outward challan $label'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            openInPane(context, ChallanDetailRoute(reversesId).location),
      );
    }
    return const SizedBox.shrink();
  }
}

/// What the challan prints for the client, and a note when the client's
/// address has been edited since.
class _ClientDetails extends StatelessWidget {
  const _ClientDetails({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = [
      challan.address,
      challan.stateName,
      'GSTIN: ${challan.gstin ?? 'none'}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.business_outlined),
          title: Text(challan.nameOnChallan),
          subtitle: Text(lines.join('\n')),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ClientDetailRoute(challan.clientId).go(context),
        ),
        if (challan.hasNewerAddress)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Text(
              "${challan.clientName}'s ${challan.addressLabel} address has "
              'been edited since. This challan keeps the details above; '
              'edit it to use the new ones.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
