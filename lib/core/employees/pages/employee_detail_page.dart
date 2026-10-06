import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../layout/two_pane_layout.dart';
import '../../layout/window_size.dart';
import '../../theme/custom_colors.dart';
import '../../utils/date_time_format.dart';
import '../../utils/money_format.dart';
import '../../widgets/adaptive_sheet.dart';
import '../../widgets/section_header.dart';
import '../models/employee.dart';
import '../models/event_type.dart';
import '../models/timeline_entry.dart';
import '../providers/employee_providers.dart';
import '../routes.dart';
import 'widgets/add_event_dialog.dart';
import 'widgets/add_payment_dialog.dart';
import '../../widgets/initials_avatar.dart';
import 'widgets/history_timeline.dart';

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
    final choice = await showAdaptiveSheet<TimelineKind>(
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
              onTap: () => Navigator.of(context).pop(TimelineKind.event),
            ),
            ListTile(
              key: const Key('add-payment-button'),
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Payment'),
              subtitle: const Text('Record money paid to them'),
              onTap: () => Navigator.of(context).pop(TimelineKind.ledger),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == TimelineKind.event) {
      showAddEventDialog(context, ref, employeeId);
    } else if (choice == TimelineKind.ledger) {
      showAddPaymentDialog(context, ref, employeeId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(employeeProvider(employeeId));
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
          DateTime? latestWithEffect(EmploymentStatus effect) => entries
              .where(
                (e) =>
                    !e.isPayment &&
                    eventTypesById[e.label]?.statusEffect == effect,
              )
              .map((e) => e.entryDate)
              .fold<DateTime?>(
                null,
                (latest, d) => latest == null || d.isAfter(latest) ? d : latest,
              );

          final status = employee.status;
          DateTime? statusSince;
          if (status == EmploymentStatus.active) {
            statusSince =
                latestWithEffect(EmploymentStatus.active) ?? employee.createdAt;
          } else if (status == EmploymentStatus.inactive) {
            statusSince = latestWithEffect(EmploymentStatus.inactive);
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96), // clear of the FAB
            children: [
              _ProfileHeader(
                employee: employee,
                isActive: !employee.isInactive,
              ),
              if (status != null)
                _StatusRow(
                  isActive: status == EmploymentStatus.active,
                  since: statusSince,
                ),
              if (employee.salary != null)
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: Text(formatRupees(employee.salary!)),
                  subtitle: const Text('Salary'),
                ),
              if (employee.notes?.trim().isNotEmpty == true)
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: Text(employee.notes!.trim()),
                  subtitle: const Text('Notes'),
                ),
              const SectionHeader('History'),
              // Wide: the add action is the first row of the history it adds
              // to. Phones: the floating button below.
              if (isTwoPane)
                AddHistoryEntryRow(
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
                            child: HistoryRow(
                              entry: entries[i],
                              eventType: entries[i].isPayment
                                  ? null
                                  : eventTypesById[entries[i].label],
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
          InitialsAvatar(name: employee.name, radius: 40, dimmed: !isActive),
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
          HistoryMarker(
            icon: isActive ? Icons.check : Icons.remove,
            background: isActive
                ? success.colorContainer
                : scheme.surfaceContainerHighest,
            foreground: isActive
                ? success.onColorContainer
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: historyMarkerGap),
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
                          ? 'Since ${formatDisplayDate(date)} · ${_durationSince(date)}'
                          : 'Left ${formatDisplayDate(date)}',
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
