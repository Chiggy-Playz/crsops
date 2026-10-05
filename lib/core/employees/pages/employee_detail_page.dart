import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../errors/app_exception.dart';
import '../../layout/two_pane_layout.dart';
import '../../layout/window_size.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../theme/custom_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/status_metadata.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../providers/employee_providers.dart';
import '../routes.dart';
import 'widgets/add_event_dialog.dart';
import 'widgets/add_payment_dialog.dart';
import 'widgets/employee_avatar.dart';

final _dateFormat = DateFormat('d MMM yyyy');
final _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// "19 days" / "3 months" / "2 years" — how long ago [since] was.
String _durationSince(DateTime since) {
  final days = DateTime.now().difference(since).inDays;
  if (days < 30) return '$days day${days == 1 ? '' : 's'}';
  if (days < 365) {
    final months = (days / 30).floor();
    return '$months month${months == 1 ? '' : 's'}';
  }
  final years = (days / 365).floor();
  return '$years year${years == 1 ? '' : 's'}';
}

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showAdaptiveSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('add-event-button'),
              leading: const Icon(Icons.event_note_outlined),
              title: const Text('Event'),
              subtitle: const Text('Joined, left, rehired, …'),
              onTap: () => Navigator.of(context).pop('event'),
            ),
            ListTile(
              key: const Key('add-payment-button'),
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payment'),
              subtitle: const Text('Record money paid to them'),
              onTap: () => Navigator.of(context).pop('payment'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'event') showAddEventDialog(context, ref, employeeId);
    if (choice == 'payment') showAddPaymentDialog(context, ref, employeeId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
    final statusAsync = ref.watch(employeeCurrentStatusProvider(employeeId));
    final timelineAsync = ref.watch(employeeTimelineProvider(employeeId));
    final eventTypesAsync = ref.watch(eventTypesProvider);
    final isTwoPane = context.isTwoPane;
    final leading = paneLeading(
      context,
      parentLocation: const EmployeesRoute().location,
    );

    return Scaffold(
      // No title: the profile header below shows the name, once.
      appBar: AppBar(
        leading: leading.leading,
        automaticallyImplyLeading: leading.implyLeading,
        actions: [
          IconButton(
            key: const Key('edit-employee-button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit employee',
            onPressed: employeeAsync.value == null
                ? null
                : () => EmployeeEditRoute(
                    employeeId,
                    $extra: employeeAsync.value,
                  ).push(context),
          ),
        ],
      ),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (employee) {
          final eventTypesById = {
            for (final t in eventTypesAsync.value ?? const <EventType>[])
              t.id: t,
          };
          final entries = timelineAsync.value ?? const <TimelineEntry>[];

          // When the current status started: the latest event whose type sets
          // it (joined/rehired → active, left → inactive).
          DateTime? latestWithEffect(String effect) => entries
              .where(
                (e) =>
                    e.kind == 'event' &&
                    eventTypesById[e.label]?.statusEffect == effect,
              )
              .map((e) => e.entryDate)
              .fold<DateTime?>(
                null,
                (latest, d) => latest == null || d.isAfter(latest) ? d : latest,
              );

          final status = statusAsync.value;
          final statusSince = status == 'active'
              ? latestWithEffect('active') ?? employee.createdAt
              : status == 'inactive'
              ? latestWithEffect('inactive')
              : null;

          return ListView(
            padding: const EdgeInsets.only(bottom: 96), // clear of the FAB
            children: [
              _ProfileHeader(
                employee: employee,
                isActive: status != 'inactive',
              ),
              if (status != null)
                _StatusRow(isActive: status == 'active', since: statusSince),
              if (employee.salary != null)
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: Text(_currencyFormat.format(employee.salary)),
                  subtitle: const Text('Salary'),
                ),
              if (employee.notes?.trim().isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: Text(employee.notes!.trim()),
                  subtitle: const Text('Notes'),
                ),
              const _SectionHeader('History'),
              // Wide: the add action is the first row of the history it adds
              // to. Phones: the floating button below.
              if (isTwoPane)
                _AddEntryRow(
                  onEvent: () => showAddEventDialog(context, ref, employeeId),
                  onPayment: () =>
                      showAddPaymentDialog(context, ref, employeeId),
                ),
              ...timelineAsync.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, _) => [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('$error'),
                  ),
                ],
                data: (entries) => entries.isEmpty
                    ? const [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No history yet'),
                        ),
                      ]
                    : [
                        for (var i = 0; i < entries.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _TimelineRow(
                              entry: entries[i],
                              eventType: entries[i].kind == 'event'
                                  ? eventTypesById[entries[i].label]
                                  : null,
                              isFirst: i == 0,
                              isLast: i == entries.length - 1,
                            ),
                          ),
                      ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: isTwoPane
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-button'),
              heroTag: 'add-entry',
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }
}

/// Contacts-style header: large centred avatar, then the name. Sits on the
/// page surface — no card — and replaces the name in the app bar.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.employee, required this.isActive});

  final Employee employee;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          EmployeeAvatar(name: employee.name, radius: 40, dimmed: !isActive),
          const SizedBox(height: 12),
          Text(
            employee.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Read-only status (M3 chips are interactive, so a chip read as a button).
/// Drawn exactly like a history row — same marker, left edge and text styles —
/// so "Active" and the "Joined" entry below it don't look like two different
/// green ticks. Inactive isn't an error, so it's neutral rather than red.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.isActive, required this.since});

  final bool isActive;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final success = context.appColors.success;
    final date = since;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Marker(
            icon: isActive ? Icons.check : Icons.remove,
            background: isActive
                ? success.colorContainer
                : scheme.surfaceContainerHighest,
            foreground: isActive
                ? success.onColorContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: _markerGap),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      isActive
                          ? 'Since ${_dateFormat.format(date)} · ${_durationSince(date)}'
                          : 'Left ${_dateFormat.format(date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _markerSize = 28.0;
const _markerGap = 16.0;

/// The round icon marker shared by the status row and history rows.
class _Marker extends StatelessWidget {
  const _Marker({
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
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
    if (entry.kind == 'ledger') {
      showAddPaymentDialog(context, ref, entry.employeeId, existing: entry);
    } else {
      showAddEventDialog(context, ref, entry.employeeId, existing: entry);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: entry.kind == 'ledger' ? 'Delete payment?' : 'Delete event?',
      message:
          'This removes "${displayLabel(entry.label)}" on ${_dateFormat.format(entry.entryDate)} entirely.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      if (entry.kind == 'ledger') {
        await ref
            .read(employeeLedgerEntryRepositoryProvider)
            .deleteEntry(entry.id);
      } else {
        await ref.read(employeeEventRepositoryProvider).deleteEvent(entry.id);
      }
      ref.invalidate(employeeTimelineProvider(entry.employeeId));
      ref.invalidate(employeeCurrentStatusProvider(entry.employeeId));
    } on AppException catch (e) {
      showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLedger = entry.kind == 'ledger';
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
                _Marker(
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
          const SizedBox(width: _markerGap),
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
                          _currencyFormat.format(entry.amount),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateFormat.format(entry.entryDate),
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
class _AddEntryRow extends StatelessWidget {
  const _AddEntryRow({required this.onEvent, required this.onPayment});

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
                _Marker(
                  icon: Icons.add,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: _markerGap),
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
