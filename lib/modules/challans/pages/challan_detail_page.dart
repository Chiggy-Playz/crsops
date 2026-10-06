import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clients/providers/client_providers.dart';
import '../../../core/clients/routes.dart';
import '../../../core/layout/two_pane_layout.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/overflow_menu.dart';
import '../../../core/widgets/section_card.dart';
import '../financial_year.dart';
import '../models/challan.dart';
import '../providers/challan_providers.dart';
import '../routes.dart';
import 'widgets/cancel_challan_dialog.dart';
import 'widgets/challan_action.dart';
import 'widgets/challan_history_section.dart';
import 'widgets/challan_pdf_button.dart';
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
          if (challan != null) ChallanPdfButton(challan: challan),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            MaxWidthBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  _Header(challan: challan),
                  ?_LinkedChallan.of(challan),
                  _ClientCard(challan: challan),
                  _ItemsCard(challan: challan),
                  _DetailsCard(challan: challan),
                  if (challan.isOutward)
                    SectionCard(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'After delivery',
                      child: FollowUpsSection(challan: challan),
                    ),
                  SectionCard(
                    icon: Icons.history,
                    title: 'History',
                    child: ChallanHistorySection(challan: challan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelReason = challan.cancelReason;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            '${challan.direction.label} challan ${challan.numberLabel}',
            style: theme.textTheme.headlineSmall,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatDisplayDate(challan.challanDate),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              ?_StatusBadge.of(context, challan),
            ],
          ),
          if (challan.isCancelled && cancelReason != null)
            Text(cancelReason, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Where the challan stands, at a glance: cancelled, or for an outward
/// challan whether the signed copy is back.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  static Widget? of(BuildContext context, Challan challan) {
    final scheme = Theme.of(context).colorScheme;
    final receivedOn = challan.receivedOn;
    if (challan.isCancelled) {
      return _StatusBadge(
        label: 'Cancelled',
        icon: Icons.block,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      );
    }
    if (!challan.isOutward) return null;
    if (receivedOn != null) {
      return _StatusBadge(
        label: 'Received ${formatDisplayDate(receivedOn)}',
        icon: Icons.task_alt,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      );
    }
    return _StatusBadge(
      label: 'Not received yet',
      icon: Icons.pending_actions,
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(icon, size: 18, color: foreground),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// The challan linked to this one by a cancellation, as a row that opens it.
class _LinkedChallan extends StatelessWidget {
  const _LinkedChallan({
    required this.icon,
    required this.text,
    required this.challanId,
  });

  final IconData icon;
  final String text;
  final String challanId;

  /// Null when no challan is linked.
  static Widget? of(Challan challan) {
    final returnedById = challan.returnedByChallanId;
    if (returnedById != null) {
      final label = challanNumberLabel(
        challan.returnedByNumber!,
        challan.returnedByFinancialYear!,
      );
      return _LinkedChallan(
        icon: Icons.call_received,
        text: 'Brought back on inward challan $label',
        challanId: returnedById,
      );
    }
    final reversesId = challan.reversesChallanId;
    if (reversesId != null) {
      final label = challanNumberLabel(
        challan.reversesNumber!,
        challan.reversesFinancialYear!,
      );
      return _LinkedChallan(
        icon: Icons.call_made,
        text: 'Brings back cancelled outward challan $label',
        challanId: reversesId,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            openInPane(context, ChallanDetailRoute(challanId).location),
      ),
    );
  }
}

/// The client as the challan prints it, and a note when the client's
/// address has been edited since.
class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final gstin = challan.gstin;

    return SectionCard(
      icon: Icons.business_outlined,
      title: 'Client',
      action: TextButton(
        onPressed: () => ClientDetailRoute(challan.clientId).go(context),
        child: const Text('Open client'),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(challan.nameOnChallan, style: theme.textTheme.titleMedium),
            Text(challan.address, style: theme.textTheme.bodyMedium),
            Text(
              gstin == null
                  ? challan.stateName
                  : '${challan.stateName} · GSTIN $gstin',
              style: muted,
            ),
            if (challan.hasNewerAddress) ...[
              const SizedBox(height: 8),
              Text(
                "${challan.clientName}'s ${challan.addressLabel} address has "
                'been edited since. This challan keeps the details above; '
                'edit it to use the new ones.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Items',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in challan.items.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${index + 1}', style: muted),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.description),
                        if (item.additionalDescription != null)
                          Text(item.additionalDescription!, style: muted),
                        if (item.serial != null)
                          Text('Serial: ${item.serial}', style: muted),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(item.quantityText),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(
              'Total ${challan.totalQuantity}',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Who took or brought the goods, the vehicle and the value as facts side by
/// side (wrapping on narrow windows), then the notes.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.challan});

  final Challan challan;

  @override
  Widget build(BuildContext context) {
    final vehicle = challan.vehicleNumber;
    final value = challan.declaredValue;
    final notes = challan.notes;

    return SectionCard(
      icon: Icons.info_outline,
      title: 'Details',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Wrap(
              spacing: 32,
              runSpacing: 16,
              children: [
                _Fact(
                  icon: Icons.person_outline,
                  value: challan.handledByName,
                  label: challan.direction.handledByLabel,
                ),
                if (vehicle != null)
                  _Fact(
                    icon: Icons.local_shipping_outlined,
                    value: vehicle,
                    label: 'Vehicle',
                  ),
                if (value != null)
                  _Fact(
                    icon: Icons.currency_rupee,
                    value: formatRupees(value),
                    label: 'Value of goods',
                  ),
              ],
            ),
            if (notes != null)
              _Fact(icon: Icons.notes, value: notes, label: 'Notes'),
          ],
        ),
      ),
    );
  }
}

/// One detail: an icon, the value, and what it is in small text under it.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: muted),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.bodyLarge),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
