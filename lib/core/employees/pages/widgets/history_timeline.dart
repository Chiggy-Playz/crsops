import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../errors/app_exception.dart';
import '../../../theme/custom_colors.dart';
import '../../../utils/date_time_format.dart';
import '../../../utils/money_format.dart';
import '../../../utils/status_metadata.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/error_snackbar.dart';
import '../../models/event_type.dart';
import '../../models/timeline_entry.dart';
import '../../providers/employee_providers.dart';
import 'add_event_dialog.dart';
import 'add_payment_dialog.dart';

// The history list on an employee's page.

const _markerSize = 28.0;

/// Space between a history marker and its text.
const historyMarkerGap = 16.0;

/// The round icon marker shared by the status row and history rows.
class HistoryMarker extends StatelessWidget {
  const HistoryMarker({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _markerSize,
      height: _markerSize,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Icon(icon, size: 16, color: foreground),
    );
  }
}

/// One entry of an employee's history (an event or a payment), drawn as a
/// node on a vertical line, with Edit / Delete in its menu.
class HistoryRow extends ConsumerWidget {
  const HistoryRow({
    super.key,
    required this.entry,
    required this.eventType,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineEntry entry;
  final EventType? eventType;
  final bool isFirst;
  final bool isLast;

  void _edit(BuildContext context, WidgetRef ref) {
    if (entry.isPayment) {
      showAddPaymentDialog(context, ref, entry.employeeId, existing: entry);
    } else {
      showAddEventDialog(context, ref, entry.employeeId, existing: entry);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: entry.isPayment ? 'Delete payment?' : 'Delete event?',
      message:
          'This removes "${displayLabel(entry.label)}" on ${formatDisplayDate(entry.entryDate)} entirely.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      if (entry.isPayment) {
        await ref
            .read(employeeLedgerEntryRepositoryProvider)
            .deleteEntry(entry.id);
        ref.invalidate(employeeTimelineProvider(entry.employeeId));
      } else {
        await ref.read(employeeEventRepositoryProvider).deleteEvent(entry.id);
        ref.read(employeeHistoryRevisionProvider.notifier).bump();
      }
    } on AppException catch (e) {
      showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLedger = entry.isPayment;
    // The node carries the colour and icon (it used to be a dot *plus* a
    // same-coloured icon). Event colours go through the M3 custom-colour
    // roles like the status badges; payments use the theme's tertiary.
    final roles = isLedger
        ? null
        : context.customColor(colorFor(eventType?.colorHex));
    final nodeBackground = roles?.colorContainer ?? scheme.tertiaryContainer;
    final nodeForeground =
        roles?.onColorContainer ?? scheme.onTertiaryContainer;
    final icon = isLedger
        ? Icons.payments_outlined
        : iconFor(eventType?.iconName);
    final note = entry.note?.trim();

    const topPadding = 10.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail: line in, node, line out. The node sits a fixed distance from
          // the top so it lines up with the title, however long the note is.
          SizedBox(
            width: _markerSize,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: topPadding,
                  color: isFirst ? Colors.transparent : scheme.outlineVariant,
                ),
                HistoryMarker(
                  icon: icon,
                  background: nodeBackground,
                  foreground: nodeForeground,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: historyMarkerGap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: topPadding + 2, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        displayLabel(entry.label),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (entry.amount != null)
                        Text(
                          formatRupees(entry.amount!),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDisplayDate(entry.entryDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (note != null && note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(note, style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _EntryMenu(
              onEdit: () => _edit(context, ref),
              onDelete: () => _delete(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overflow menu for a history entry — M3 MenuAnchor (keyboard navigation,
/// focus handling) rather than the older PopupMenuButton. Delete is in the
/// error colour so it doesn't look as harmless as Edit.
class _EntryMenu extends StatelessWidget {
  const _EntryMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return MenuAnchor(
      // Off by default in Flutter; turns on the M3 open/close motion.
      animated: true,
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_outline, color: error),
          style: MenuItemButton.styleFrom(foregroundColor: error),
          onPressed: onDelete,
          child: const Text('Delete'),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: 'More options',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// "Add event or payment" as the first History row on wide windows, opening
/// an anchored, animated menu (Event / Payment) instead of the phone sheet.
/// Uses the history rows' own marker and spacing, not the list-pane
/// ListActionRow, so it matches the rows beneath it.
class AddHistoryEntryRow extends StatelessWidget {
  const AddHistoryEntryRow({
    super.key,
    required this.onEvent,
    required this.onPayment,
  });

  final VoidCallback onEvent;
  final VoidCallback onPayment;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      animated: true,
      menuChildren: [
        MenuItemButton(
          key: const Key('add-event-button'),
          leadingIcon: const Icon(Icons.event_note_outlined),
          onPressed: onEvent,
          child: const Text('Event'),
        ),
        MenuItemButton(
          key: const Key('add-payment-button'),
          leadingIcon: const Icon(Icons.payments_outlined),
          onPressed: onPayment,
          child: const Text('Payment'),
        ),
      ],
      // Built like a history row (same 28px marker, edge, gap and text style)
      // so it reads as part of the list it adds to.
      builder: (context, controller, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return InkWell(
          key: const Key('add-button'),
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                HistoryMarker(
                  icon: Icons.add,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: historyMarkerGap),
                Text(
                  'Add event or payment',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
